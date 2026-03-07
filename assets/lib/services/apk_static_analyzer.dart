import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';

class ApkStaticAnalyzer {
  final ThreatIntel _threatIntel = ThreatIntel();

  /// Analyzes a raw APK file from storage for static threats.
  /// Follows the new lightweight Octane scoring system.
  Future<Threat?> analyzeApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // Read a limited chunk of the APK or the whole thing if it's small
      // For speed, we only read the bytes once and decode as ZIP
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      List<String> reasons = [];
      int threatScore = 0;
      List<String> foundPermissions = [];
      String packageName = filePath.split('/').last; 
      String appName = packageName;

      // 1. Extract Manifest Data (Basic string scanning approach)
      String? rawManifestContent;

      for (final archiveFile in archive) {
        final name = archiveFile.name.toLowerCase();

        if (name == 'androidmanifest.xml') {
           rawManifestContent = String.fromCharCodes(archiveFile.content as List<int>)
              .replaceAll(RegExp(r'[^\x20-\x7E]'), ' '); // Keep only printable ASCII
           break; 
        }
      }

      if (rawManifestContent != null) {
        // Extract Permissions via regex pattern matching
        final permissionRegex = RegExp(r'android\.permission\.[A-Z_]+');
        final permsSet = permissionRegex.allMatches(rawManifestContent)
            .map((m) => m.group(0) as String).toSet();
        foundPermissions = permsSet.toList();

        // Heuristic Scoring (Aligned with ThreatAnalyzer)
        if (rawManifestContent.contains('AccessibilityService')) {
          reasons.add('APK contains AccessibilityService implementation');
          threatScore += 30;
        }
        if (rawManifestContent.contains('DeviceAdminReceiver')) {
          reasons.add('APK attempts to request Device Admin privileges');
          threatScore += 30;
        }
        if (rawManifestContent.contains('android.intent.action.BOOT_COMPLETED')) {
          reasons.add('APK configured to start automatically on boot');
          threatScore += 10;
        }
        
        // Check for Overlay permission in manifest strings
        if (foundPermissions.contains('android.permission.SYSTEM_ALERT_WINDOW')) {
          reasons.add('APK requests Window Overlay permission');
          threatScore += 15;
        }

        // Side-loaded indicator (since it's a raw APK file)
        reasons.add('Sideloaded APK installer detected');
        threatScore += 15; // Higher base risk for raw files

        // Package Name detection
        final packageRegex = RegExp(r'([a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+)');
        final packageMatch = packageRegex.firstMatch(rawManifestContent);
        if (packageMatch != null) {
          packageName = packageMatch.group(0)!;
        }
      }

      // 2. Final Evaluation (0-30 Safe, 30-60 Suspicious, 60+ Malware)
      if (threatScore >= 30) {
         return Threat(
          appName: appName,
          packageName: packageName,
          riskLevel: threatScore >= 60 ? 'MALWARE' : 'SUSPICIOUS',
          threatScore: threatScore.clamp(0, 100),
          reasons: reasons,
          permissionsRequested: foundPermissions,
          recommendedAction: 'Suspicious APK file detected. Delete immediately.',
          threatType: 'file'
        );
      }

    } catch (e) {
      debugPrint('[ApkStaticAnalyzer] Error analyzing $filePath: $e');
    }
    
    return null; 
  }
}
