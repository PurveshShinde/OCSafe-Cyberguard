import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApkScanner {
  /// Scans common download directories for APK and ZIP files.
  /// Returns a list of paths to found suspicious files.
  Future<List<String>> scanForSuspiciousFiles() async {
    List<String> foundFiles = [];

    // Request permissions based on Android version
    bool canReadStorage = await _requestStoragePermission();
    if (!canReadStorage) {
      // Cannot scan without permission
      return foundFiles;
    }

    final List<String> directoriesToScan = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
    ];

    for (String dirPath in directoriesToScan) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          final List<FileSystemEntity> entities = await dir.list(recursive: false).toList();
          for (var entity in entities) {
            if (entity is File) {
              final path = entity.path.toLowerCase();
              if (path.endsWith('.apk') || path.endsWith('.xapk') || path.endsWith('.apks') || path.endsWith('.zip') || path.endsWith('.rar')) {
                foundFiles.add(entity.path);
              }
            }
          }
        } catch (e) {
          // Ignore permission denied to specific folders
        }
      }
    }

    return foundFiles;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) { // Android 13+
        // If we just want to search for files, MANAGE_EXTERNAL_STORAGE is powerful 
        // but required for non-media files like APKs on newer Androids via standard dart:io.
        // Let's try manageExternalStorage first, if not we fallback.
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) return true;
        
        // Due to strict policies, many apps ask for READ_MEDIA_* + manage if needed.
        // But for .apk files specifically in Downloads, manageExternalStorage or Storage Access Framework is needed.
        // Returning true if it's granted, else we might fail to read.
        return false;
      } else if (androidInfo.version.sdkInt >= 30) { // Android 11+
         final status = await Permission.manageExternalStorage.request();
         return status.isGranted;
      } else {
        // Below Android 11
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return false;
  }
}
