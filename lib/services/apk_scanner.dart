import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApkScanner {
  /// Suspicious file extensions to flag.
  static const List<String> _suspiciousExtensions = [
    '.apk', '.xapk', '.apks', '.apkm',
    '.zip', '.rar', '.7z',
    '.dex', '.jar', '.so',
  ];

  /// Root directories to scan on Android.
  /// NOTE: /sdcard is a symlink to /storage/emulated/0 — do NOT include both
  /// or every file will be detected twice.
  static const List<String> _rootDirectoriesToScan = [
    '/storage/emulated/0',
    '/data/local/tmp',         // Commonly used by ADB/sideload
  ];

  /// Directories to always include even if permission is restrictive.
  static const List<String> _priorityDirectories = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/DCIM',
    '/storage/emulated/0/Pictures',
    '/storage/emulated/0/Android/data',
    '/storage/emulated/0/Android/obb',
    '/storage/emulated/0/WhatsApp/Media',
    '/storage/emulated/0/Telegram',
  ];

  /// Maximum recursion depth for directory scanning.
  static const int _maxDepth = 6;

  /// Scans the entire accessible device storage for suspicious files.
  /// Returns a list of absolute paths to found suspicious files.
  /// NOTE: Permission must be requested BEFORE calling this (via the UI layer).
  Future<List<String>> scanForSuspiciousFiles() async {
    final List<String> foundFiles = [];

    // Check if we already have permission — do NOT request here (this is called
    // mid-scan from a background context; permission would fail silently).
    final bool hasFullAccess = await hasStoragePermission();

    final List<String> dirsToScan = hasFullAccess
        ? _rootDirectoriesToScan
        : _priorityDirectories;

    for (final dirPath in dirsToScan) {
      await _scanDirectory(dirPath, foundFiles, depth: 0);
    }

    // Deduplicate paths (guard against any remaining symlink duplicates)
    return foundFiles.toSet().toList();
  }

  /// Recursively scans a directory up to [_maxDepth] levels deep.
  Future<void> _scanDirectory(
    String dirPath,
    List<String> foundFiles, {
    required int depth,
  }) async {
    if (depth > _maxDepth) return;

    final dir = Directory(dirPath);
    if (!await dir.exists()) return;

    try {
      final entities = dir.listSync(recursive: false, followLinks: false);
      for (final entity in entities) {
        try {
          if (entity is File) {
            final lowerPath = entity.path.toLowerCase();
            if (_suspiciousExtensions.any((ext) => lowerPath.endsWith(ext))) {
              foundFiles.add(entity.path);
            }
          } else if (entity is Directory) {
            // Skip proc/sys virtual FS to avoid hangs
            final name = entity.path.split('/').last.toLowerCase();
            if (name == 'proc' || name == 'sys' || name == 'dev') continue;
            await _scanDirectory(entity.path, foundFiles, depth: depth + 1);
          }
        } catch (_) {
          // Skip files/dirs we can't access
        }
      }
    } catch (_) {
      // Directory access denied — skip silently
    }
  }

  /// Native method channel for storage permission — bypasses permission_handler
  /// which doesn't work reliably on Android 16+ for MANAGE_EXTERNAL_STORAGE.
  static const _storageChannel = MethodChannel('com.ocsafe.cyberguard/storage_permission');

  /// Checks current storage permission status WITHOUT requesting it.
  /// Returns true if the app already has "All Files Access" (Android 11+)
  /// or READ_EXTERNAL_STORAGE (Android 9/10).
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        // Calls Environment.isExternalStorageManager() natively
        final bool granted = await _storageChannel.invokeMethod<bool>('check_all_files_access') ?? false;
        debugPrint('[ApkScanner] hasStoragePermission (API${androidInfo.version.sdkInt}): $granted');
        return granted;
      } else {
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      debugPrint('[ApkScanner] hasStoragePermission error: $e');
      return false;
    }
  }

  /// Opens the "All Files Access" settings page for this app (Android 11+)
  /// or shows the standard storage permission dialog (Android 9/10).
  /// Returns `true` immediately if already granted, `false` after launching Settings.
  /// The caller is responsible for polling [hasStoragePermission] afterwards.
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      debugPrint('[ApkScanner] requestStoragePermission (API$sdkInt)');

      if (sdkInt >= 30) {
        // Uses Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION natively.
        // Returns true instantly if already granted, false after opening Settings.
        final bool alreadyGranted =
            await _storageChannel.invokeMethod<bool>('request_all_files_access') ?? false;
        debugPrint('[ApkScanner] request_all_files_access returned: $alreadyGranted');
        return alreadyGranted;
      } else {
        PermissionStatus status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('[ApkScanner] requestStoragePermission error: $e');
      return false;
    }
  }
}

