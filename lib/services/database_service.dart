import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/models/vt_result.dart';

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
      version: 3,
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
          vt_malicious INTEGER DEFAULT 0,
          vt_suspicious INTEGER DEFAULT 0,
          vt_checked INTEGER DEFAULT 0,
          confidence INTEGER DEFAULT 0,
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

        await db.execute('''
        CREATE TABLE vt_cache (
          hash TEXT PRIMARY KEY,
          package_name TEXT NOT NULL,
          version_code TEXT,
          malicious INTEGER DEFAULT 0,
          suspicious INTEGER DEFAULT 0,
          undetected INTEGER DEFAULT 0,
          harmless INTEGER DEFAULT 0,
          checked_at TEXT NOT NULL
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
        await db.execute(
          'CREATE INDEX idx_vt_package ON vt_cache(package_name)',
        );
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
              "ALTER TABLE threats ADD COLUMN threat_type TEXT NOT NULL DEFAULT 'app'",
            );
          } catch (_) {}

          try {
            await db.execute(
              "ALTER TABLE scan_results ADD COLUMN scan_mode TEXT NOT NULL DEFAULT 'limited'",
            );
          } catch (_) {}
        }

        if (oldVersion < 3) {
          // Safe migration: each ALTER wrapped in try/catch
          try {
            await db.execute(
              'ALTER TABLE threats ADD COLUMN vt_malicious INTEGER DEFAULT 0',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE threats ADD COLUMN vt_suspicious INTEGER DEFAULT 0',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE threats ADD COLUMN vt_checked INTEGER DEFAULT 0',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE threats ADD COLUMN confidence INTEGER DEFAULT 0',
            );
          } catch (_) {}

          // Create VT cache table
          await db.execute('''
          CREATE TABLE IF NOT EXISTS vt_cache (
            hash TEXT PRIMARY KEY,
            package_name TEXT NOT NULL,
            version_code TEXT,
            malicious INTEGER DEFAULT 0,
            suspicious INTEGER DEFAULT 0,
            undetected INTEGER DEFAULT 0,
            harmless INTEGER DEFAULT 0,
            checked_at TEXT NOT NULL
          )
          ''');

          try {
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vt_package ON vt_cache(package_name)',
            );
          } catch (_) {}
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
    await db.delete('vt_cache');
  }

  Future<void> clearScanHistory() async {
    final db = await database;
    await db.delete('scan_results');
    await db.delete('threats');
  }

  Future<void> deleteScanResultByDate(String isoDate) async {
    final db = await database;
    await db.delete('scan_results', where: 'scan_date = ?', whereArgs: [isoDate]);
  }

  // ─── VirusTotal Cache Methods ──────────────────────────────────────

  /// Cache a VT lookup result.
  Future<void> cacheVTResult(VTResult result) async {
    final db = await database;
    await db.insert(
      'vt_cache',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached VT result by hash. Returns null if not cached or expired (24h TTL).
  Future<VTResult?> getVTCache(
    String hash, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    final db = await database;

    final maps = await db.query(
      'vt_cache',
      where: 'hash = ?',
      whereArgs: [hash],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final result = VTResult.fromMap(maps.first);

    // Check if expired
    if (result.isExpired(ttl: ttl)) {
      await db.delete('vt_cache', where: 'hash = ?', whereArgs: [hash]);
      return null;
    }

    return result;
  }

  /// Get cached VT result by package name + optional versionCode.
  /// Returns null if not found, expired (24h TTL), or version has changed.
  Future<VTResult?> getVTCacheByPackage(
    String packageName, {
    String? versionCode,
    Duration ttl = const Duration(hours: 24),
  }) async {
    final db = await database;

    String where = 'package_name = ?';
    List<dynamic> whereArgs = [packageName];

    if (versionCode != null) {
      where += ' AND version_code = ?';
      whereArgs.add(versionCode);
    }

    final maps = await db.query(
      'vt_cache',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'checked_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final result = VTResult.fromMap(maps.first);

    if (result.isExpired(ttl: ttl)) {
      return null;
    }

    return result;
  }

  /// Remove all expired VT cache entries (older than 24h by default).
  Future<void> clearExpiredVTCache({
    Duration ttl = const Duration(hours: 24),
  }) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(ttl).toIso8601String();

    await db.delete(
      'vt_cache',
      where: 'checked_at < ?',
      whereArgs: [cutoff],
    );
  }
}
