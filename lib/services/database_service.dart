import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ocsafe_cyberguard_v2.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE scan_results (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          scan_date TEXT NOT NULL,
          total_apps_scanned INTEGER NOT NULL,
          threat_count INTEGER NOT NULL,
          security_score INTEGER NOT NULL,
          scan_mode TEXT NOT NULL DEFAULT 'limited'
        )
        ''');

        await db.execute('''
        CREATE TABLE threats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          scan_id INTEGER NOT NULL,
          app_name TEXT NOT NULL,
          package_name TEXT NOT NULL,
          risk_level TEXT NOT NULL,
          threat_score INTEGER NOT NULL,
          reasons TEXT NOT NULL,
          permissions TEXT NOT NULL,
          recommendation TEXT NOT NULL,
          threat_type TEXT NOT NULL DEFAULT 'app',
          FOREIGN KEY (scan_id) REFERENCES scan_results (id) ON DELETE CASCADE
        )
        ''');

        await db.execute('''
        CREATE TABLE activity_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
        ''');

        /// Performance indexes
        await db.execute(
          'CREATE INDEX idx_threats_scan_id ON threats(scan_id)',
        );
        await db.execute(
          'CREATE INDEX idx_threats_package ON threats(package_name)',
        );
        await db.execute(
          'CREATE INDEX idx_logs_timestamp ON activity_logs(timestamp)',
        );
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE threats ADD COLUMN threat_type TEXT NOT NULL DEFAULT 'app'",
          );

          await db.execute(
            "ALTER TABLE scan_results ADD COLUMN scan_mode TEXT NOT NULL DEFAULT 'limited'",
          );
        }
      },
    );
  }

  Future<int> insertScanResult(ScanResult result) async {
    final db = await database;

    int scanId = 0;

    await db.transaction((txn) async {
      scanId = await txn.insert('scan_results', result.toMap());

      for (final threat in result.threats) {
        final threatMap = threat.toMap();

        threatMap['scan_id'] = scanId;
        threatMap.remove('id');

        await txn.insert('threats', threatMap);
      }
    });

    return scanId;
  }

  Future<List<ScanResult>> getScanHistory() async {
    final db = await database;

    final scanMaps = await db.query(
      'scan_results',
      orderBy: 'scan_date DESC',
      limit: 50,
    );

    final List<ScanResult> results = [];

    for (final scanMap in scanMaps) {
      final scanId = scanMap['id'] as int;

      final threatMaps = await db.query(
        'threats',
        where: 'scan_id = ?',
        whereArgs: [scanId],
      );

      final threats = threatMaps.map((m) => Threat.fromMap(m)).toList();

      results.add(ScanResult.fromMap(scanMap, threats: threats));
    }

    return results;
  }

  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await database;

    return db.insert('activity_logs', log.toMap());
  }

  Future<List<ActivityLog>> getActivityLogs({int limit = 20}) async {
    final db = await database;

    final maps = await db.query(
      'activity_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((m) => ActivityLog.fromMap(m)).toList();
  }

  Future<void> removeThreatsByPackageName(String packageName) async {
    final db = await database;

    await db.delete(
      'threats',
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  Future<void> clearAll() async {
    final db = await database;

    await db.delete('threats');
    await db.delete('scan_results');
    await db.delete('activity_logs');
  }
}
