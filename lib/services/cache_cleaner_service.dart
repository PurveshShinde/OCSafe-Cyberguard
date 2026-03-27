import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:ocsafe_cyberguard/services/database_service.dart';

class CacheCleanerService {
  static const int _maxFilesScanned = 5000;

  Future<List<Directory>> getCacheDirectories() async {
    List<Directory> dirs = [];
    
    // 1. Internal Temp/Cache Directory
    try {
      final tempDir = await getTemporaryDirectory();
      dirs.add(tempDir);
    } catch (e) {
      debugPrint('Error getting temp directory: $e');
    }

    // 2. External Cache Directories (Scoped Storage Safe)
    try {
      final extDirs = await getExternalCacheDirectories();
      if (extDirs != null) {
        dirs.addAll(extDirs);
      }
    } catch (e) {
      debugPrint('Error getting external cache directories: $e');
    }

    // 3. Optional Fallback Directories (Scoped Storage Safe Heuristics)
    try {
      final extStorageDir = await getExternalStorageDirectory();
      if (extStorageDir != null) {
        final rootPath = extStorageDir.path.split('Android')[0];

        // Download
        final downloadDir = Directory('${rootPath}Download');
        if (await downloadDir.exists()) dirs.add(downloadDir);

        // System Thumbnails (huge source of hidden junk)
        final dcimThumbs = Directory('${rootPath}DCIM/.thumbnails');
        if (await dcimThumbs.exists()) dirs.add(dcimThumbs);

        final picThumbs = Directory('${rootPath}Pictures/.thumbnails');
        if (await picThumbs.exists()) dirs.add(picThumbs);
        
        final moviesThumbs = Directory('${rootPath}Movies/.thumbnails');
        if (await moviesThumbs.exists()) dirs.add(moviesThumbs);
      }
    } catch (e) {
      debugPrint('Error getting fallback directories: $e');
    }

    return dirs;
  }

  Future<Map<String, dynamic>> getCacheSize() async {
    final dirs = await getCacheDirectories();
    final paths = dirs.map((d) => d.path).toList();

    // Run heavy operations in background isolate
    final result = await compute(_calculateCacheSizeInIsolate, paths);
    
    final double sizeMB = result / (1024 * 1024);
    return {
      'success': true,
      'sizeMB': double.parse(sizeMB.toStringAsFixed(2)),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static int _calculateCacheSizeInIsolate(List<String> directoryPaths) {
    int totalSize = 0;
    int filesScanned = 0;

    void scanDirectory(Directory dir, String basePath) {
      if (filesScanned > _maxFilesScanned) return;
      try {
        final entities = dir.listSync(recursive: false, followLinks: false);
        for (final entity in entities) {
          if (filesScanned > _maxFilesScanned) return;
          
          if (entity is File) {
            filesScanned++;
            if (_isJunkFile(entity, basePath)) {
              try {
                totalSize += entity.lengthSync();
              } catch (_) {}
            }
          } else if (entity is Directory) {
            scanDirectory(entity, basePath);
          }
        }
      } catch (_) {
        // Skip inaccessible sub-directory securely without crashing the parent scan
      }
    }

    for (String path in directoryPaths) {
      if (filesScanned > _maxFilesScanned) break;
      final directory = Directory(path);
      if (directory.existsSync()) {
        scanDirectory(directory, path);
      }
    }
    return totalSize;
  }

  Future<Map<String, dynamic>> cleanCache() async {
    final dirs = await getCacheDirectories();
    final paths = dirs.map((d) => d.path).toList();

    // Run heavy clearing logic in a background isolate
    final result = await compute(_clearCacheInIsolate, paths);

    int freedBytes = result['freedBytes'] as int;
    int filesDeleted = result['filesDeleted'] as int;
    bool success = result['success'] as bool;
    
    double freedMB = freedBytes / (1024 * 1024);
    final formattedMB = double.parse(freedMB.toStringAsFixed(2));

    if (filesDeleted > 0 || success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_cache_cleanup', DateTime.now().toIso8601String());

      if (filesDeleted > 0) {
        await _logCleanupEvent(formattedMB, filesDeleted);
      }
    }

    return {
      'success': success,
      'freedMB': formattedMB,
      'filesDeleted': filesDeleted,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _clearCacheInIsolate(List<String> directoryPaths) {
    int freedBytes = 0;
    int filesDeleted = 0;
    int filesScanned = 0;
    bool success = true;

    void cleanDirectory(Directory dir, String basePath) {
      if (filesScanned > _maxFilesScanned) return;
      try {
        final entities = dir.listSync(recursive: false, followLinks: false);
        for (final entity in entities) {
          if (filesScanned > _maxFilesScanned) return;

          if (entity is File) {
            filesScanned++;
            if (_isJunkFile(entity, basePath)) {
              try {
                if (entity.existsSync()) {
                  final size = entity.lengthSync();
                  entity.deleteSync();
                  freedBytes += size;
                  filesDeleted++;
                }
              } catch (e) {
                success = false;
              }
            }
          } else if (entity is Directory) {
            cleanDirectory(entity, basePath);
          }
        }
      } catch (e) {
        success = false;
        // Skip inaccessible sub-directory securely without crashing the parent scan
      }
    }

    for (String path in directoryPaths) {
      if (filesScanned > _maxFilesScanned) break;
      final directory = Directory(path);
      if (directory.existsSync()) {
        cleanDirectory(directory, path);
      }
    }

    return {
      'success': success,
      'freedBytes': freedBytes,
      'filesDeleted': filesDeleted,
    };
  }

  static bool _isJunkFile(File file, String basePath) {
    try {
      final lowerPath = file.path.toLowerCase();
      
      // 1. Condition: Files directly within the app's cache directory or thumbnails
      if (basePath.contains('Android/data/') || 
          basePath.contains('/data/user/') || 
          basePath.contains('/data/data/') ||
          lowerPath.contains('/.thumbnails/')) {
        return true;
      }

      // 2. Condition: 0-byte files
      final int size = file.lengthSync();
      if (size == 0) {
        return true;
      }

      final String fileName = file.path.split('/').last.toLowerCase();

      // 3. Condition: Junk extensions (Broadened)
      final bool hasJunkExtension = fileName.endsWith('.tmp') || 
                                    fileName.endsWith('.log') || 
                                    fileName.endsWith('.cache') ||
                                    fileName.endsWith('.bak') ||
                                    fileName.endsWith('.old') ||
                                    fileName.endsWith('.chk') ||
                                    fileName.endsWith('.temp');
      
      if (hasJunkExtension) {
        return true;
      }

      // 4. Muted condition for custom temp files names
      if (fileName.contains('temp') || fileName.contains('cache')) {
        final stat = file.statSync();
        final daysOld = DateTime.now().difference(stat.accessed).inDays;
        if (daysOld > 7) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _logCleanupEvent(double freedMB, int filesDeleted) async {
    try {
      final log = ActivityLog(
        message: 'Cache cleaned: ${freedMB}MB freed ($filesDeleted files)',
        type: ActivityType.protection, // Using an existing ActivityType
        timestamp: DateTime.now(),
      );
      await DatabaseService().insertActivityLog(log);
    } catch (e) {
      debugPrint('Error logging cache clean: $e');
    }
  }
}
