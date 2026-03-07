import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/models/app_scan_result.dart';
import 'package:ocsafe_cyberguard/services/permission_scanner.dart';

import 'package:ocsafe_cyberguard/services/stealth_app_detector.dart';
import 'package:ocsafe_cyberguard/services/signature_scanner.dart';

class ThreatAnalyzer {
  final PermissionScanner _permissionScanner = PermissionScanner();
  final StealthAppDetector _stealthAppDetector = StealthAppDetector();

  static int analyze(AppInfo app) {
    final analyzer = ThreatAnalyzer();
    final threat = analyzer.analyzeApp(app);
    return threat?.threatScore ?? 0;
  }

  static AppScanResult analyzeFull(AppInfo app) {
    final analyzer = ThreatAnalyzer();
    final threat = analyzer.analyzeApp(app);
    String reason = 'Safe';
    if (threat != null) {
      reason = threat.reasons.isNotEmpty ? threat.reasons.first : 'Suspicious patterns';
    }
    return AppScanResult(
      app.appName.isEmpty ? app.packageName : app.appName,
      app.packageName,
      threat?.threatScore ?? 0,
      reason: reason,
    );
  }

  // --- Expanded suspicious keyword list ---
  static const List<String> suspiciousKeywords = [
    'hack', 'spy', 'tracker', 'keylog', 'stealth', 'hidden', 'monitor',
    'record', 'inject', 'exploit', 'malware', 'virus', 'trojan', 'worm',
    'rootkit', 'rat', 'backdoor', 'phish', 'scam', 'spoof', 'crack',
    'bypass', 'cheat', 'prank', 'fake', 'cloneapp', 'mirror',
    'adware', 'clicker', 'adserving', 'popups',
  ];

  // --- Known malware / AV-test package names ---
  // Includes EICAR-equivalent Android AV test packages used by av-test.org,
  // and widely recognized riskware package names.
  static const List<String> knownMaliciousPackages = [
    // AV Test (av-test.org standard test apps)
    'org.av_test.antivirus_test_file',
    'com.av_test.testfile',
    'org.avtest.malware',
    'com.avtest',

    // IKARUS / AV vendor test apps
    'com.ikarus.test',
    'at.ikarus.test',

    // Common test/eicar-style packages
    'com.eicar',
    'org.eicar',
    'com.example.malware',
    'com.test.malware',
    'com.test.virus',
    'com.test.trojan',

    // Cerberus banking trojan (well-documented)
    'com.cerberus.rat',
    'com.android.jsi.manager',  // Common Cerberus disguise

    // Flubot / Cabassous
    'com.tencent.mobileqq.flubot',

    // SpyNote / DroidJack family
    'com.spynote.android',
    'com.droidjack',

    // AndroRAT
    'com.example.androrat',
    'com.androrat',

    // Joker malware family (common package patterns)
    'com.joke.android',

    // Known sideloaded knockoffs
    'com.whatsapp.gb',
    'com.gbwhatsapp',
    'com.fm.whatsapp',
    'com.yowhatsapp',
    'com.aero.whatsapp',

    // Fake system packages (common malware disguise)
    'com.android.service.manager',
    'com.android.google.service',
    'com.android.system.update.manager',
    'com.system.service.helper',

    // Known Adware / Clickers
    'com.mub.zqavw', // User reported stealth adware
    'com.adware.clicker',
    'com.mobile.adserving',
  ];

  // --- Known legitimate whitelisted apps (to avoid false positives) ---
  static const Map<String, String> popularAppsWhitelist = {
    'whatsapp': 'com.whatsapp',
    'facebook': 'com.facebook.katana',
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
    'telegram': 'org.telegram.messenger',
    'snapchat': 'com.snapchat.android',
    'twitter': 'com.twitter.android',
    'tiktok': 'com.zhiliaoapp.musically',
    'spotify': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
  };

  // --- Known legitimate hidden apps (allowlist for stealth checks) ---
  static const List<String> safeHiddenPackages = [
    // Core Google/Android
    'com.google.android.gms',
    'com.android.systemui',
    'com.android.vending',
    'com.google.android.gsf',
    'com.google.android.ext.services',
    'com.google.android.as', // Android System Intelligence
    'com.google.android.networkstack.tethering',
    'com.android.keychain',
    'com.android.settings',

    // Common OEMs (OnePlus, Samsung, Xiaomi, etc.)
    'com.oneplus.widget',
    'net.oneplus.widget',
    'com.oneplus.security',
    'com.oneplus.camera.service',
    'com.oplus.security',
    'com.oplus.battery',
    'com.oplus.pay',
    'com.samsung.android.lool',
    'com.samsung.android.securitylogagent',
    'com.xiaomi.discover',
    'com.coloros.safecenter',
    'com.heytap.mcs',

    // Other System level components
    'com.android.providers.media.module',
    'com.android.providers.telephony',
    'com.android.bluetooth',
    'com.android.nfc',
    'com.android.certinstaller',
    
    // Media / Companion Apps mentioned by user
    'com.android.soundrecorder',
    'com.heytap.speechassist',
    'com.google.android.setupwizard',
    'com.coloros.lockassistant', // Lock screen magazine
    'com.heytap.pictorial', // Lock screen magazine alternative
  ];

  /// Main method for analyzing an app on the fly.
  /// Follows the new lightweight Octane scoring system.
  Threat? analyzeApp(AppInfo app, [List<String> trustedPackages = const []]) {
    // 1. Ignore the CyberGuard app itself and trusted packages
    if (app.packageName.contains('ocsafe') || 
        app.packageName.contains('cyberguard') ||
        trustedPackages.contains(app.packageName)) {
      return null;
    }

    // 2. System apps are automatically safe as per Octane rules
    if (app.isSystemApp) return null;

    int totalScore = 0;
    List<String> reasons = [];
    final String displayName = app.appName.isEmpty ? app.packageName : app.appName;

    // 3. Simple Heuristic Scoring
    
    // Accessibility Permission (+30)
    if (app.requestedPermissions.contains('android.permission.BIND_ACCESSIBILITY_SERVICE')) {
      reasons.add('Requests Accessibility Service (potential for automation abuse)');
      totalScore += 30;
    }

    // System Overlay (+15)
    if (app.requestedPermissions.contains('android.permission.SYSTEM_ALERT_WINDOW')) {
      reasons.add('Requests Overlay permission (can display content over other apps)');
      totalScore += 15;
    }

    // Auto-start on boot (+10)
    if (app.requestedPermissions.contains('android.permission.RECEIVE_BOOT_COMPLETED')) {
      reasons.add('Starts automatically on device boot');
      totalScore += 10;
    }

    // Unknown Installer (+10)
    if (app.installSource == null || app.installSource!.isEmpty || app.installSource!.contains('packageinstaller')) {
      reasons.add('Installed from unknown source (Side-loaded)');
      totalScore += 10;
    }

    // Not from Play Store (+5)
    if (app.installSource != 'com.android.vending') {
      reasons.add('Not verified by Play Store');
      totalScore += 5;
    }

    // 4. Threshold Evaluation
    // 0-30: SAFE
    // 30-60: SUSPICIOUS
    // 60+: MALWARE
    
    if (totalScore < 30) return null;

    String riskLevel = 'SUSPICIOUS';
    String recommendation = 'Review app permissions or uninstall if unfamiliar.';
    
    if (totalScore >= 60) {
      riskLevel = 'MALWARE';
      recommendation = 'DANGEROUS: App shows multiple threat indicators. Uninstall recommended.';
    }

    return Threat(
      appName: displayName,
      packageName: app.packageName,
      riskLevel: riskLevel,
      threatScore: totalScore.clamp(0, 100),
      reasons: reasons,
      permissionsRequested: app.requestedPermissions,
      recommendedAction: recommendation,
    );
  }

  /// Evaluates files found in storage. APKs are HIGH risk, ZIPs are only flagged if they have malware indicators in contents.
  List<Threat> evaluateSuspiciousFiles(List<String> filePaths) {
    List<Threat> threats = [];
    
    for (final path in filePaths) {
      final fileName = path.split('/').last;
      final lowerName = fileName.toLowerCase();
      final isZip = lowerName.endsWith('.zip') || lowerName.endsWith('.rar');
      final isApk = lowerName.endsWith('.apk');

      if (isApk) {
        // APK logic remains robust
        bool isMalwareName = lowerName.contains('avtest') || lowerName.contains('eicar') || lowerName.contains('malware');
        threats.add(Threat(
          appName: fileName,
          packageName: path,
          riskLevel: 'HIGH',
          threatScore: isMalwareName ? 90 : 60,
          reasons: [
            if (isMalwareName) 'File with malware-related name detected',
            'Sideloaded APK installer detected — bypasses Play Store verification',
          ],
          permissionsRequested: [],
          recommendedAction: 'Delete this APK unless you trust the source.',
          threatType: 'file',
        ));
      } else if (isZip) {
        // Refined Archive Inspection
        final archiveIndicators = _inspectArchiveContents(path);
        if (archiveIndicators.isNotEmpty) {
          threats.add(Threat(
            appName: fileName,
            packageName: path,
            riskLevel: 'HIGH',
            threatScore: archiveIndicators.any((i) => i.contains('signature')) ? 100 : 70,
            reasons: archiveIndicators,
            permissionsRequested: [],
            recommendedAction: 'Archive contains suspicious content. Immediate removal recommended.',
            threatType: 'file',
          ));
        }
      }
    }
    
    return threats;
  }

  /// Inspects ZIP/RAR contents for malicious indicators.
  List<String> _inspectArchiveContents(String filePath) {
    List<String> indicators = [];
    try {
      final file = File(filePath);
      if (!file.existsSync()) return [];

      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final innerName = file.name.toLowerCase();
        
        if (innerName.endsWith('.apk') || innerName.endsWith('.exe') || innerName.endsWith('.dex')) {
          indicators.add('Archive contains executable file: ${file.name}');
        }
        
        if (innerName.contains('eicar')) {
          indicators.add('Known malware test signature detected in archive.');
        }

        // Potential for deep string search in small text files could be added here
      }
    } catch (e) {
      // If we can't extract (e.g. encrypted or wrong format), we don't flag as malware by default
      debugPrint('Could not inspect archive $filePath: $e');
    }
    return indicators;
  }
}
