import 'dart:io';
import 'package:archive/archive.dart';

class ApkStaticAnalyzer {
  /// Maximum archive size to inspect (50MB safety limit)
  static const int _maxArchiveSize = 50 * 1024 * 1024;

  /// Suspicious filenames
  static const List<String> _suspiciousNames = [
    'payload',
    'dropper',
    'inject',
    'hack',
    'crack',
    'exploit',
    'patch',
    'update',
    'loader',
    'rat',
    'backdoor',
  ];

  /// Suspicious extensions
  static const List<String> _suspiciousExtensions = [
    '.apk',
    '.dex',
    '.so',
    '.exe',
    '.bin',
    '.elf',
    '.sh',
  ];

  static List<String> inspectArchiveContents(String filePath) {
    final Set<String> indicators = {};

    try {
      final file = File(filePath);

      if (!file.existsSync()) return [];

      /// Prevent large archive memory attacks
      if (file.lengthSync() > _maxArchiveSize) {
        indicators.add(
          'Archive too large to safely inspect (possible archive bomb).',
        );
        return indicators.toList();
      }

      final bytes = file.readAsBytesSync();

      final archive = ZipDecoder().decodeBytes(bytes, verify: false);

      int dexCount = 0;
      bool manifestFound = false;

      for (final archiveFile in archive) {
        final innerName = archiveFile.name.toLowerCase();

        /// Suspicious extensions
        if (_suspiciousExtensions.any((ext) => innerName.endsWith(ext))) {
          indicators.add(
            'Archive contains executable component: ${archiveFile.name}',
          );
        }

        /// Suspicious names
        if (_suspiciousNames.any((name) => innerName.contains(name))) {
          indicators.add(
            'Archive contains suspicious file name: ${archiveFile.name}',
          );
        }

        /// Embedded APK droppers
        if (innerName.endsWith('.apk')) {
          indicators.add(
            'Archive contains embedded APK installer: ${archiveFile.name}',
          );
        }

        /// DEX payloads
        if (innerName.endsWith('.dex')) {
          dexCount++;
        }

        /// AndroidManifest detection
        if (innerName.contains('androidmanifest.xml')) {
          manifestFound = true;
        }

        /// EICAR test malware signature
        if (innerName.contains('eicar')) {
          indicators.add('Known malware test signature detected.');
        }

        /// Shell scripts
        if (innerName.endsWith('.sh')) {
          indicators.add('Archive contains executable shell script.');
        }

        /// Native libraries
        if (innerName.contains('/lib/') && innerName.endsWith('.so')) {
          indicators.add('Archive contains native executable library.');
        }
      }

      /// Multi-dex detection
      if (dexCount > 2) {
        indicators.add(
          'Archive contains multiple DEX files (possible multi-stage payload).',
        );
      }

      /// APK structure detection
      if (manifestFound && dexCount > 0) {
        indicators.add(
          'Archive appears to contain a full Android application structure.',
        );
      }
    } catch (_) {
      /// Ignore corrupted archives
    }

    return indicators.toList();
  }
}
