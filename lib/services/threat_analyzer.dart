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

    // 5.2 Adware Behavioral Detection (Overlays + Internet + AutoStart on untrusted apps)
    bool isAdwareKeyword = packageLower.contains('adware') || packageLower.contains('clicker') || app.appName.toLowerCase().contains('adware');
    bool hasAdwareBehavior = app.requestedPermissions.contains('android.permission.SYSTEM_ALERT_WINDOW') && 
                             app.requestedPermissions.contains('android.permission.INTERNET') &&
                             app.requestedPermissions.contains('android.permission.RECEIVE_BOOT_COMPLETED');
                             
    bool isTrustedNamespaceAdwareCheck = app.packageName.startsWith('com.android.') ||
                              app.packageName.startsWith('com.google.') ||
                              app.packageName.startsWith('com.samsung.') ||
                              app.packageName.startsWith('com.oneplus.') ||
                              app.packageName.startsWith('com.oplus.') ||
                              app.packageName.startsWith('com.coloros.') ||
                              app.packageName.startsWith('com.xiaomi.') ||
                              app.packageName.startsWith('com.huawei.') ||
                              app.packageName.startsWith('com.heytap.');

    if (!app.isSystemApp && !isTrustedNamespaceAdwareCheck && !popularAppsWhitelist.values.contains(app.packageName)) {
        if (isAdwareKeyword || hasAdwareBehavior) {
            reasons.add('Adware Characteristics: App behavior strongly suggests intrusive advertising or click-fraud.');
            totalScore += 60;
            if (recommendation.contains('Review app usage')) {
                recommendation = 'Adware detected. This app may drain battery and display intrusive advertisements over other apps. Uninstall recommended.';
            }
        }
    }

    // 5.5 Hidden App Detection (No Launcher Icon + Suspicious Permissions)
    // Check allowlist AND common trusted namespaces (Google, OEMs, Android System)
    bool isTrustedNamespace = app.packageName.startsWith('com.android.') ||
                              app.packageName.startsWith('com.google.') ||
                              app.packageName.startsWith('com.samsung.') ||
                              app.packageName.startsWith('com.oneplus.') ||
                              app.packageName.startsWith('com.oplus.') ||
                              app.packageName.startsWith('com.coloros.') ||
                              app.packageName.startsWith('com.xiaomi.') ||
                              app.packageName.startsWith('com.huawei.') ||
                              app.packageName.startsWith('com.heytap.');

    if (!app.isSystemApp && 
        !app.hasLaunchIntent && 
        !safeHiddenPackages.contains(app.packageName) &&
        !isTrustedNamespace) {
      print("🕵️ Hidden app detected: ${app.packageName} (${app.appName})");
      reasons.add('Hidden App: No launcher icon.');
      int hiddenScore = 40;

      if (app.requestedPermissions.contains('android.permission.RECEIVE_BOOT_COMPLETED')) {
        hiddenScore += 20;
        reasons.add('Runs automatically on boot.');
      }
      if (app.requestedPermissions.contains('android.permission.BIND_ACCESSIBILITY_SERVICE')) {
        hiddenScore += 40;
        reasons.add('Uses accessibility service.');
      }
      if (app.requestedPermissions.contains('android.permission.SYSTEM_ALERT_WINDOW')) {
        hiddenScore += 30;
        reasons.add('Uses overlay attack permission.');
      }
      if (app.requestedPermissions.contains('android.permission.FOREGROUND_SERVICE')) {
        hiddenScore += 20;
        reasons.add('Runs in background (foreground service).');
      }
      if (app.requestedPermissions.contains('android.permission.INTERNET')) {
        hiddenScore += 10;
        reasons.add('Has network capability.');
      }

      totalScore += hiddenScore;
      if (recommendation == 'Review app usage or uninstall if unfamiliar.') {
          recommendation = 'App hides from your app drawer and has suspicious permissions. This is a common tactic for stealth malware. Uninstall highly recommended.';
      } else if (totalScore >= 70 && recommendation.contains('Review app usage')) {
          recommendation = 'High risk: App is hidden and severely overly-privileged. Uninstall highly recommended.';
      }
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

  /// Evaluates files found in storage. APKs are HIGH risk, ZIPs are MEDIUM risk unless they have malware names.
  List<Threat> evaluateSuspiciousFiles(List<String> filePaths) {
    return filePaths.map((path) {
      final fileName = path.split('/').last;
      final lowerName = fileName.toLowerCase();
      final isZip = lowerName.endsWith('.zip') || lowerName.endsWith('.rar');

      // Check if file name itself contains a known AV-test or malware pattern
      bool isMalwareName = lowerName.contains('avtest') ||
          lowerName.contains('av_test') ||
          lowerName.contains('eicar') ||
          lowerName.contains('malware') ||
          lowerName.contains('virus') ||
          lowerName.contains('trojan');

      return Threat(
        appName: fileName,
        packageName: path, // Store the absolute path here so we can delete the file
        riskLevel: isMalwareName ? 'HIGH' : (isZip ? 'MEDIUM' : 'HIGH'),
        threatScore: isMalwareName ? 90 : (isZip ? 50 : 60),
        reasons: isMalwareName
            ? [
                'File with malware-related name detected in storage',
                isZip ? 'Archives can contain malicious payloads' : 'Sideloaded APK installer — bypasses Play Store verification',
              ]
            : [
                isZip ? 'Compressed archive detected' : 'Sideloaded APK installer detected — bypasses Play Store security verification',
                isZip ? 'Archives downloaded from the internet may contain hidden malware' : 'Unverified apps can contain hidden malware',
              ],
        permissionsRequested: [],
        recommendedAction: isZip 
            ? 'Delete this archive file unless you explicitly downloaded it and trust its source.' 
            : 'Delete this APK unless you explicitly downloaded it from a trusted source.',
      );
    }).toList();
  }
}
