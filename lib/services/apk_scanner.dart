import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

@pragma('vm:entry-point')
List<String> scanDirectoriesBackground(Map<String, dynamic> params) {
  final List<String> dirsToScan = params['dirsToScan'];
  final List<String> extensions = params['extensions'];
  final int maxDepth = params['maxDepth'];

  final List<String> foundFiles = [];

  for (final dirPath in dirsToScan) {
    _scanDirectoryBackgroundSync(
      dirPath,
      foundFiles,
      extensions,
      depth: 0,
      maxDepth: maxDepth,
    );
  }

  return foundFiles;
}

const int _maxFilesPerDirectory = 2000;
const int _maxFileSize = 500 * 1024 * 1024; // 500MB

const List<String> _ignoredDirectoryNames = [
  'cache',
  'temp',
  'tmp',
  'thumbnails',
];

void _scanDirectoryBackgroundSync(
  String dirPath,
  List<String> foundFiles,
  List<String> extensions, {
  required int depth,
  required int maxDepth,
}) {
  if (depth > maxDepth) return;

  final dir = Directory(dirPath);
  if (!dir.existsSync()) return;

  int scannedFiles = 0;

  try {
    final entities = dir.listSync(recursive: false, followLinks: false);

    for (final entity in entities) {
      if (scannedFiles > _maxFilesPerDirectory) break;

      try {
        if (entity is File) {
          scannedFiles++;

          if (entity.lengthSync() > _maxFileSize) continue;

          final path = entity.path;
          final lowerPath = path.toLowerCase();

          if (extensions.any((ext) => lowerPath.endsWith(ext))) {
            foundFiles.add(path);
          }
        } else if (entity is Directory) {
          final name = entity.path.split('/').last.toLowerCase();

          if (name == 'proc' || name == 'sys' || name == 'dev') continue;

          if (_ignoredDirectoryNames.contains(name)) continue;

          _scanDirectoryBackgroundSync(
            entity.path,
            foundFiles,
            extensions,
            depth: depth + 1,
            maxDepth: maxDepth,
          );
        }
      } catch (_) {}
    }
  } catch (_) {}
}

class ApkScanner {
  static const List<String> _suspiciousExtensions = [
    '.apk',
    '.xapk',
    '.apks',
    '.apkm',
    '.zip',
    '.rar',
    '.7z',
    '.dex',
    '.jar',
    '.so',
  ];

  static const List<String> _rootDirectoriesToScan = [
    '/storage/emulated/0',
    '/data/local/tmp',
  ];

  static const List<String> _priorityDirectories = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/DCIM',
    '/storage/emulated/0/Pictures',
    '/storage/emulated/0/Movies',
    '/storage/emulated/0/WhatsApp/Media',
    '/storage/emulated/0/WhatsApp/Documents',
    '/storage/emulated/0/Telegram',
  ];

  /// Quick Scan uses depth=3 (fast, covers Download/WhatsApp/Telegram).
  /// Deep  Scan uses depth=6 (thorough, covers nested archives/dirs).
  static const int quickScanDepth = 3;
  static const int deepScanDepth  = 6;

  Future<List<String>> scanForSuspiciousFiles({int depth = quickScanDepth}) async {
    final bool hasFullAccess = await hasStoragePermission();

    final List<String> dirsToScan = hasFullAccess
        ? _rootDirectoriesToScan
        : _priorityDirectories;

    final List<String> backgroundFoundFiles =
        await compute(scanDirectoriesBackground, {
          'dirsToScan': dirsToScan,
          'extensions': _suspiciousExtensions,
          'maxDepth': depth,
        });

    return backgroundFoundFiles.toSet().toList();
  }

  static const _storageChannel = MethodChannel(
    'com.ocsafe.cyberguard/storage_permission',
  );

  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        final bool granted =
            await _storageChannel.invokeMethod<bool>(
              'check_all_files_access',
            ) ??
            false;

        debugPrint(
          '[ApkScanner] hasStoragePermission (API${androidInfo.version.sdkInt}): $granted',
        );

        return granted;
      } else {
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      debugPrint('[ApkScanner] hasStoragePermission error: $e');
      return false;
    }
  }

  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      debugPrint('[ApkScanner] requestStoragePermission (API$sdkInt)');

      if (sdkInt >= 30) {
        final bool alreadyGranted =
            await _storageChannel.invokeMethod<bool>(
              'request_all_files_access',
            ) ??
            false;

        debugPrint(
          '[ApkScanner] request_all_files_access returned: $alreadyGranted',
        );

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
