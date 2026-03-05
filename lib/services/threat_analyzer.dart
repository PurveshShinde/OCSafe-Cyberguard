import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/permission_scanner.dart';

class ThreatAnalyzer {
  final PermissionScanner _permissionScanner = PermissionScanner();

  // --- Expanded suspicious keyword list ---
  static const List<String> suspiciousKeywords = [
    'hack', 'spy', 'tracker', 'keylog', 'stealth', 'hidden', 'monitor',
    'record', 'inject', 'exploit', 'malware', 'virus', 'trojan', 'worm',
    'rootkit', 'rat', 'backdoor', 'phish', 'scam', 'spoof', 'crack',
    'bypass', 'cheat', 'prank', 'fake', 'cloneapp', 'mirror',
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

  /// Main method for analyzing an app on the fly.
  Threat? analyzeApp(AppInfo app) {
    if (app.isSystemApp) return null;

    List<String> reasons = [];
    int totalScore = 0;
    String recommendation = 'Review app usage or uninstall if unfamiliar.';
    String riskLevel = 'LOW';
    List<String> perms = app.requestedPermissions
        .where((p) => PermissionScanner.dangerousPermissionsList.contains(p))
        .toList();

    // 1. Known malware package blocklist (highest priority check)
    final packageLower = app.packageName.toLowerCase();
    bool isKnownMalware = knownMaliciousPackages
        .any((known) => packageLower == known.toLowerCase());
    if (isKnownMalware) {
      reasons.add('Known malicious package detected in threat database');
      totalScore += 100;
      riskLevel = 'HIGH';
      recommendation = 'DANGEROUS: Known malware detected! Uninstall immediately.';
      // Return early — no need for further checks
      return Threat(
        appName: app.appName,
        packageName: app.packageName,
        riskLevel: riskLevel,
        threatScore: totalScore,
        reasons: reasons,
        permissionsRequested: perms,
        recommendedAction: recommendation,
      );
    }

    // 2. Check package name contains AV-test or malware-related patterns
    bool isAvTestApp = packageLower.contains('avtest') ||
        packageLower.contains('av_test') ||
        packageLower.contains('av-test') ||
        packageLower.contains('eicar') ||
        packageLower.contains('testmalware') ||
        packageLower.contains('malwaretest') ||
        packageLower.contains('antivirus_test') ||
        packageLower.contains('antivirustest');
    if (isAvTestApp) {
      reasons.add('AV test / security test application detected');
      totalScore += 80;
      riskLevel = 'HIGH';
      recommendation = 'This is an antivirus test file. Treat as HIGH risk if not intentionally installed.';
    }

    // 3. Check Permissions using PermissionScanner
    final permissionThreat = _permissionScanner.analyzeAppPermissions(app);
    if (permissionThreat != null) {
      reasons.addAll(permissionThreat.reasons);
      totalScore += permissionThreat.threatScore;
      if (recommendation == 'Review app usage or uninstall if unfamiliar.') {
        recommendation = permissionThreat.recommendedAction;
      }
      perms = permissionThreat.permissionsRequested;
    }

    // 4. Suspicious Package Name Keywords
    bool isSuspiciousPackage = suspiciousKeywords
        .any((keyword) => packageLower.contains(keyword));
    if (isSuspiciousPackage) {
      reasons.add('Suspicious keywords found in package name');
      totalScore += 30;
      recommendation = 'Highly suspicious app. Immediate uninstall recommended.';
    }

    // 5. Fake App Detection (Impersonation)
    bool isFakeApp = false;
    popularAppsWhitelist.forEach((name, realPackage) {
      if (app.appName.toLowerCase().contains(name) &&
          app.packageName != realPackage) {
        isFakeApp = true;
      }
    });
    if (isFakeApp) {
      reasons.add('App impersonates popular application (e.g., WhatsApp, Instagram)');
      totalScore += 40;
      recommendation = 'Fake app detected. Immediate uninstall strongly recommended.';
    }

    // 6. Unknown Install Source — flag only when combined with other issues
    if (app.installSource == null ||
        (!app.installSource!.contains('android.vending') &&
            !app.installSource!.contains('google'))) {
      if (totalScore > 0) {
        reasons.add('Installed from unknown source (side-loaded)');
        totalScore += 20;
      }
    }

    if (totalScore > 0) {
      totalScore = totalScore > 100 ? 100 : totalScore;

      if (totalScore >= 60) {
        riskLevel = 'HIGH';
      } else if (totalScore >= 30) {
        riskLevel = 'MEDIUM';
      } else {
        riskLevel = 'LOW';
      }

      return Threat(
        appName: app.appName,
        packageName: app.packageName,
        riskLevel: riskLevel,
        threatScore: totalScore,
        reasons: reasons,
        permissionsRequested: perms,
        recommendedAction: recommendation,
      );
    }

    return null;
  }

  /// Evaluates APK files found in storage — always HIGH risk (sideloaded unverified installer).
  List<Threat> evaluateApks(List<String> apkPaths) {
    return apkPaths.map((path) {
      final fileName = path.split('/').last;
      final lowerName = fileName.toLowerCase();

      // Check if APK name itself contains a known AV-test or malware pattern
      bool isMalwareApk = lowerName.contains('avtest') ||
          lowerName.contains('av_test') ||
          lowerName.contains('eicar') ||
          lowerName.contains('malware') ||
          lowerName.contains('virus') ||
          lowerName.contains('trojan');

      return Threat(
        appName: fileName,
        packageName: 'Unverified APK Installer',
        riskLevel: isMalwareApk ? 'HIGH' : 'HIGH',
        threatScore: isMalwareApk ? 90 : 60,
        reasons: isMalwareApk
            ? [
                'APK file with malware-related name detected in storage',
                'Sideloaded APK installer — bypasses Play Store verification',
              ]
            : [
                'Sideloaded APK installer detected — bypasses Play Store security verification',
                'Unverified apps can contain hidden malware',
              ],
        permissionsRequested: [],
        recommendedAction: 'Delete this APK unless you explicitly downloaded it from a trusted source.',
      );
    }).toList();
  }
}
