import 'dart:io';
import 'package:archive/archive.dart';

class ApkStaticAnalyzer {
  /// Scans an archive file (assuming it's safe to read)
  static List<String> inspectArchiveContents(String filePath) {
    List<String> indicators = [];
    try {
      final file = File(filePath);
      if (!file.existsSync()) return [];

      final bytes = file.readAsBytesSync();
      // Important: verify: false avoids fully unpacking/loading streams and spiking memory
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);

      for (final archiveFile in archive) {
        final innerName = archiveFile.name.toLowerCase();

        if (innerName.endsWith('.apk') ||
            innerName.endsWith('.exe') ||
            innerName.endsWith('.dex') ||
            innerName.endsWith('.so') ||
            innerName.endsWith('.sh') ||
            innerName.contains('payload') ||
            innerName == 'classes.dex') {
          indicators.add('Archive contains suspicious file: ${archiveFile.name}');
        }

        if (innerName.contains('eicar')) {
          indicators.add('Known malware test signature detected in archive.');
        }
      }
    } catch (e) {
      // If we can't extract (e.g. encrypted or wrong format), we don't flag as malware by default
    }
    return indicators;
  }
}
