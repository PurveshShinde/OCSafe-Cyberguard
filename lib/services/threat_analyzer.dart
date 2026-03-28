import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/app_features.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/risk_scoring_engine.dart';
import 'package:ocsafe_cyberguard/services/signature_scanner.dart';
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
  final RiskScoringEngine _scoringEngine = RiskScoringEngine();

  /// Cache for already scanned packages
  final Map<String, Threat?> _analysisCache = {};

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

  bool _isTrustedNamespace(String packageName) {
    for (final ns in trustedNamespaces) {
      if (packageName.startsWith(ns)) return true;
    }
    return false;
  }

  Threat? analyzeApp(AppInfo app) {
    if (_analysisCache.containsKey(app.packageName)) {
      return _analysisCache[app.packageName];
    }

    final displayName = app.appName.trim().isEmpty
        ? app.packageName
        : app.appName;

    /// Known malware detection (fast path — always check)
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
        confidence: 100,
      );

      _analysisCache[app.packageName] = threat;
      return threat;
    }

    /// Skip trusted apps
    if (app.isSystemApp || _isTrustedNamespace(app.packageName)) {
      _analysisCache[app.packageName] = null;
      return null;
    }

    // ── Extract features & delegate to centralized scoring engine ──
    final features = AppFeatures.fromAppInfo(app);
    final riskScore = _scoringEngine.evaluate(features);

    if (riskScore.score < 15) {
      _analysisCache[app.packageName] = null;
      return null;
    }

    final threat = Threat(
      appName: displayName,
      packageName: app.packageName,
      riskLevel: riskScore.riskLevel,
      threatScore: riskScore.score,
      reasons: riskScore.reasons,
      permissionsRequested: riskScore.flaggedPermissions,
      recommendedAction: riskScore.recommendedAction,
      confidence: riskScore.confidence,
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
            confidence: 70,
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
              confidence: 85,
            ),
          );
        }
      }
    }

    return threats;
  }
}
