import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';

/// SQLite database service for persisting scan history and activity logs.
class DatabaseService {
  static Database? _database;

  /// Gets the database instance, creating it if needed.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ocsafe_cyberguard.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scan_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scan_date TEXT NOT NULL,
            total_apps_scanned INTEGER NOT NULL,
            threat_count INTEGER NOT NULL,
            security_score INTEGER NOT NULL
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
      },
    );
  }

  /// Inserts a scan result and returns its id.
  Future<int> insertScanResult(ScanResult result) async {
    final db = await database;
    return await db.insert('scan_results', result.toMap());
  }

  /// Gets all scan results ordered by date descending.
  Future<List<ScanResult>> getScanHistory() async {
    final db = await database;
    final maps = await db.query(
      'scan_results',
      orderBy: 'scan_date DESC',
      limit: 50,
    );
    return maps.map((m) => ScanResult.fromMap(m)).toList();
  }

  /// Inserts an activity log entry.
  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await database;
    return await db.insert('activity_logs', log.toMap());
  }

  /// Gets recent activity logs.
  Future<List<ActivityLog>> getActivityLogs({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'activity_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => ActivityLog.fromMap(m)).toList();
  }

  /// Clears all data (for testing/reset).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('scan_results');
    await db.delete('activity_logs');
  }
}
