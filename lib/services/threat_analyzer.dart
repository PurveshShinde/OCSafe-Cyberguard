import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/permission_scanner.dart';
import 'package:ocsafe_cyberguard/services/signature_scanner.dart';
import 'package:ocsafe_cyberguard/services/stealth_app_detector.dart';
import 'package:ocsafe_cyberguard/services/apk_static_analyzer.dart';

@pragma('vm:entry-point')
List<Threat> runThreatAnalysisBackground(List<AppInfo> apps) {
  final analyzer = ThreatAnalyzer();
  final List<Threat> threats = [];

  for (final app in apps) {
    final threat = analyzer.analyzeApp(app);
    if (threat != null) threats.add(threat);
  }

  return threats;
}

@pragma('vm:entry-point')
List<Threat> evaluateSuspiciousFilesBackground(List<String> filePaths) {
  final analyzer = ThreatAnalyzer();
  return analyzer.evaluateSuspiciousFiles(filePaths);
}

class ThreatAnalyzer {
  final PermissionScanner _permissionScanner = PermissionScanner();

  /// Cache for already scanned packages
  final Map<String, Threat?> _analysisCache = {};

  static const List<String> suspiciousKeywords = [
    'hack',
    'spy',
    'keylog',
    'stealth',
    'inject',
    'exploit',
    'trojan',
    'rat',
    'backdoor',
    'phish',
    'spoof',
    'crack',
    'bypass',
    'fake',
    'clone',
    'adware',
    'clicker',
  ];

  static const List<String> trustedNamespaces = [
    'com.android.',
    'com.google.',
    'com.samsung.',
    'com.oneplus.',
    'com.oplus.',
    'com.coloros.',
    'com.heytap.',
    'com.miui.',
    'com.xiaomi.',
    'com.huawei.',
  ];

  static const List<String> knownMaliciousPackages = [
    'org.av_test.antivirus_test_file',
    'com.eicar',
    'com.example.malware',
    'com.spynote.android',
    'com.androrat',
    'com.cerberus.rat',
    'com.gbwhatsapp',
    'com.fm.whatsapp',
    'com.yowhatsapp',
    'com.aero.whatsapp',
    'com.android.service.manager',
    'com.android.system.update.manager',
    'com.mub.zqavw',
  ];

  static const Map<String, String> popularAppsWhitelist = {
    'whatsapp': 'com.whatsapp',
    'facebook': 'com.facebook.katana',
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
    'telegram': 'org.telegram.messenger',
    'spotify': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
  };

  bool _isTrustedNamespace(String packageName) {
    for (final ns in trustedNamespaces) {
      if (packageName.startsWith(ns)) return true;
    }
    return false;
  }

  bool _isPlayStoreApp(AppInfo app) {
    if (app.installSource == null) return false;
    return app.installSource!.contains('android.vending');
  }

  bool _isSideloaded(AppInfo app) {
    if (app.isSystemApp) return false;
    if (_isPlayStoreApp(app)) return false;
    return true;
  }

  Threat? analyzeApp(AppInfo app) {
    if (_analysisCache.containsKey(app.packageName)) {
      return _analysisCache[app.packageName];
    }

    final displayName = app.appName.trim().isEmpty
        ? app.packageName
        : app.appName;

    final packageLower = app.packageName.toLowerCase();
    final nameLower = displayName.toLowerCase();

    /// Known malware detection
    if (!app.isSystemApp &&
        (SignatureScanner.isMaliciousPackage(app.packageName) ||
            knownMaliciousPackages.contains(app.packageName))) {
      final threat = Threat(
        appName: displayName,
        packageName: app.packageName,
        riskLevel: 'HIGH',
        threatScore: 100,
        reasons: ['Known malicious package detected in threat database'],
        permissionsRequested: [],
        recommendedAction:
            'DANGEROUS: Known malware detected. Uninstall immediately.',
      );

      _analysisCache[app.packageName] = threat;
      return threat;
    }

    /// Skip trusted apps
    if (app.isSystemApp || _isTrustedNamespace(app.packageName)) {
      _analysisCache[app.packageName] = null;
      return null;
    }

    final sideloaded = _isSideloaded(app);

    List<String> reasons = [];
    int totalScore = 0;
    String recommendation = 'Review app usage if unfamiliar.';

    List<String> perms = [];

    /// Permission analysis
    final permissionThreat = _permissionScanner.analyzeAppPermissions(app);

    if (permissionThreat != null) {
      reasons.addAll(permissionThreat.reasons);
      totalScore += permissionThreat.threatScore;
      recommendation = permissionThreat.recommendedAction;
      perms = permissionThreat.permissionsRequested;
    }

    /// Keyword detection
    if (sideloaded) {
      final suspicious = suspiciousKeywords.any(
        (k) => packageLower.contains(k) || nameLower.contains(k),
      );

      if (suspicious) {
        reasons.add('Suspicious keyword detected in app name or package');
        totalScore += 20;
      }
    }

    /// Fake app detection
    for (final entry in popularAppsWhitelist.entries) {
      if (nameLower.contains(entry.key) && app.packageName != entry.value) {
        reasons.add('Possible impersonation of popular application');
        totalScore += 35;
        recommendation = 'Fake application detected. Uninstall recommended.';
        break;
      }
    }

    /// Stealth malware detection
    if (StealthAppDetector.isStealthApp(app)) {
      reasons.add('Hidden or stealth application detected');
      totalScore += 50;
    }

    /// Unknown install source
    if (sideloaded && totalScore > 0) {
      reasons.add('Application installed from unknown source');
      totalScore += 10;
    }

    if (totalScore <= 0) {
      _analysisCache[app.packageName] = null;
      return null;
    }

    if (totalScore > 100) totalScore = 100;

    String riskLevel;

    if (totalScore >= 70) {
      riskLevel = 'HIGH';
    } else if (totalScore >= 35) {
      riskLevel = 'MEDIUM';
    } else {
      riskLevel = 'LOW';
    }

    final threat = Threat(
      appName: displayName,
      packageName: app.packageName,
      riskLevel: riskLevel,
      threatScore: totalScore,
      reasons: reasons,
      permissionsRequested: perms,
      recommendedAction: recommendation,
    );

    _analysisCache[app.packageName] = threat;

    return threat;
  }

  List<Threat> evaluateSuspiciousFiles(List<String> filePaths) {
    List<Threat> threats = [];

    for (final path in filePaths) {
      final fileName = path.split('/').last;
      final lowerName = fileName.toLowerCase();

      if (lowerName.endsWith('.apk')) {
        threats.add(
          Threat(
            appName: fileName,
            packageName: path,
            riskLevel: 'MEDIUM',
            threatScore: 50,
            reasons: [
              'Sideloaded APK installer detected (bypasses Play Store protection)',
            ],
            permissionsRequested: [],
            recommendedAction: 'Only install APK files from trusted sources.',
            threatType: 'file',
          ),
        );
      } else if (lowerName.endsWith('.zip') || lowerName.endsWith('.rar')) {
        final indicators = ApkStaticAnalyzer.inspectArchiveContents(path);

        if (indicators.isNotEmpty) {
          threats.add(
            Threat(
              appName: fileName,
              packageName: path,
              riskLevel: 'HIGH',
              threatScore: 80,
              reasons: indicators,
              permissionsRequested: [],
              recommendedAction:
                  'Archive contains suspicious content. Delete immediately.',
              threatType: 'file',
            ),
          );
        }
      }
    }

    return threats;
  }
}
