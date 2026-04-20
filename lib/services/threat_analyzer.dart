import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/app_features.dart';
import 'package:ocsafe_cyberguard/models/app_role.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/risk_scoring_engine.dart';
import 'package:ocsafe_cyberguard/services/reputation_service.dart';
import 'package:ocsafe_cyberguard/services/apk_static_analyzer.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';

/// Background isolate entry point for batch app analysis.
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

/// Background isolate entry point for suspicious file evaluation.
@pragma('vm:entry-point')
List<Threat> evaluateSuspiciousFilesBackground(List<String> filePaths) {
  final analyzer = ThreatAnalyzer();
  return analyzer.evaluateSuspiciousFiles(filePaths);
}

/// Orchestrates the full threat detection pipeline for an installed app.
///
/// Pipeline (v2):
///   1. Reputation Layer   — hash + package name DB (override exit on match)
///   2. Trusted namespace  — system/OEM skip (fast exit)
///   3. Feature extraction — [AppFeatures.fromAppInfo]
///   4. Scoring engine     — [RiskScoringEngine] (capability + correlation)
///   5. Threshold check    — discard SAFE results (score < role threshold)
///   6. RiskContext build  — assemble structured output
class ThreatAnalyzer {
  final RiskScoringEngine _scoringEngine = RiskScoringEngine();
  final ReputationService _reputation = ReputationService();

  /// Cache for already-analyzed packages (package name → Threat?).
  final Map<String, Threat?> _analysisCache = {};

  static const List<String> _trustedNamespaces = [
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

  bool _isTrustedNamespace(String packageName) {
    for (final ns in _trustedNamespaces) {
      if (packageName.startsWith(ns)) return true;
    }
    return false;
  }

  // ─── Main analysis entry point ─────────────────────────────────────────

  /// Analyze a single installed app and return a [Threat] if one is detected.
  ///
  /// Returns `null` if the app is considered safe.
  Threat? analyzeApp(AppInfo app, {String? apkHash}) {
    if (_analysisCache.containsKey(app.packageName)) {
      return _analysisCache[app.packageName];
    }

    final displayName =
        app.appName.trim().isEmpty ? app.packageName : app.appName;

    // ── Step 1: Reputation layer — fast override paths ─────────────────────
    final reputation = _reputation.check(
      packageName: app.packageName,
      apkHash: apkHash,
    );

    if (reputation.isKnownMalware) {
      // Hard override — confirmed malware, no heuristics needed
      final threat = Threat(
        appName: displayName,
        packageName: app.packageName,
        riskLevel: 'HIGH',
        threatScore: 100,
        reasons: [
          'Confirmed malware: ${reputation.label}',
          'Package matched known threat database',
        ],
        permissionsRequested: [],
        recommendedAction:
            'DANGEROUS: Confirmed malware detected. Uninstall immediately.',
        confidence: 100,
        riskContext: RiskContext(
          appRole: 'Known Malware',
          installSourceLabel: 'N/A',
          capabilityFlags: const ['CONFIRMED_MALWARE'],
        ),
      );
      _analysisCache[app.packageName] = threat;
      return threat;
    }

    // ── Step 2: Trusted namespace / system app fast exit ───────────────────
    if (app.isSystemApp || _isTrustedNamespace(app.packageName)) {
      _analysisCache[app.packageName] = null;
      return null;
    }

    // ── Step 3: If known-safe, cap the heuristic score at 20 ──────────────
    // We still run heuristics but suppress high-risk flags for trusted apps.
    final knownSafe = reputation.isKnownSafe;

    // ── Step 4: Feature extraction ────────────────────────────────────────
    final features = AppFeatures.fromAppInfo(app);

    // ── Step 4.5: Source-based smart gate ─────────────────────────────────
    // Play Store / OEM Store apps are generally safe.
    // EXCEPTION: If a Play Store app has INSTALL_PACKAGES + INTERNET, it IS
    // a riskware pattern (Priority 1) — but cap it at LOW (score ≤ 34).
    // Pure Play Store apps with no dangerous installer capability → skip.
    final isTrustedStore = features.isPlayStoreApp ||
        features.installSourceTier == InstallSourceTier.trustedStore;
    final isRiskwareCandidate =
        features.hasInstallPackagesPerm && features.hasInternetPerm;

    if (isTrustedStore && !isRiskwareCandidate) {
      // Completely safe from a trusted store — no dangerous capability
      _analysisCache[app.packageName] = null;
      return null;
    }
    // If isTrustedStore && isRiskwareCandidate: fall through to scoring
    // but we will cap the final score at 34 (→ LOW) below.

    // ── Step 5: Run the scoring engine ────────────────────────────────────
    final riskScore = _scoringEngine.evaluate(features);

    // Apply known-safe cap
    int finalScore = riskScore.score;
    String finalLevel = riskScore.riskLevel;
    List<String> finalReasons = riskScore.reasons;

    if (knownSafe && finalScore > 20) {
      finalScore = 20;
      finalLevel = 'LOW';
      finalReasons = [
        'App is on trusted package list — score capped at 20',
        ...riskScore.reasons,
      ];
    }

    // ── Step 6: Threshold check — discard SAFE results ────────────────────
    // Minimum score of 15 to generate a threat report.
    // However, if the app is from a trusted store, require MEDIUM risk (35) 
    // to avoid flagging clean browsers/messengers that just use a lot of permissions.
    final int discardThreshold = isTrustedStore ? 35 : 15;
    if (finalScore < discardThreshold) {
      _analysisCache[app.packageName] = null;
      return null;
    }

    // ── Step 7: Build RiskContext + derive threatCategory (Priority 3) ──────
    final capFlags = riskScore.capabilityFlags;
    // Type: malware if high-severity capability, riskware if installer pattern
    final bool isMalwareType = capFlags.any((f) =>
        f == 'ACCESSIBILITY_ABUSE' ||
        f == 'DEVICE_ADMIN' ||
        f == 'RISKWARE_ADWARE_PERSISTENT' ||
        f == 'RISKWARE_INSTALL_DOWNLOAD_CRITICAL');
    final bool isRiskwareType = !isMalwareType &&
        capFlags.any((f) => f.startsWith('RISKWARE_') || f == 'CAN_INSTALL_APPS');
    final String threatCategory =
        isMalwareType ? 'malware' : (isRiskwareType ? 'riskware' : 'app');

    final riskContext = RiskContext(
      appRole: capFlags.contains('RISKWARE_THIRD_PARTY_STORE')
          ? 'Riskware — Third-party app store'
          : capFlags.contains('RISKWARE_INSTALL_DOWNLOAD')
              ? 'Riskware — Installer (Play Store)'
              : features.appRole.label,
      installSourceLabel: features.installSourceTier.label,
      capabilityFlags: capFlags,
    );

    // ── Step 8: Assemble Threat ────────────────────────────────────────────
    final threat = Threat(
      appName: displayName,
      packageName: app.packageName,
      riskLevel: finalLevel,
      threatScore: finalScore,
      reasons: finalReasons,
      permissionsRequested: riskScore.flaggedPermissions,
      recommendedAction: riskScore.recommendedAction,
      confidence: riskScore.confidence,
      riskContext: riskContext,
      threatType: threatCategory,
    );

    _analysisCache[app.packageName] = threat;
    return threat;
  }

  // ─── File threat evaluation ────────────────────────────────────────────

  List<Threat> evaluateSuspiciousFiles(List<String> filePaths) {
    final threats = <Threat>[];

    for (final path in filePaths) {
      final fileName = path.split('/').last;
      final lowerName = fileName.toLowerCase();

      if (lowerName.endsWith('.apk')) {
        // Check reputation by filename pattern (no hash available for files yet)
        final knownMalware = ThreatIntel.hasSuspiciousNamespace(
              path.split('/').last.toLowerCase(),
            ) ||
            ThreatIntel.hasFakeSystemPattern(
              path.split('/').last.toLowerCase(),
            );

        threats.add(
          Threat(
            appName: fileName,
            packageName: path,
            riskLevel: knownMalware ? 'HIGH' : 'MEDIUM',
            threatScore: knownMalware ? 75 : 50,
            reasons: [
              'Sideloaded APK installer detected (bypasses Play Store protection)',
              if (knownMalware)
                'Suspicious file name pattern matches known malware naming',
            ],
            permissionsRequested: const [],
            recommendedAction:
                'Only install APK files from trusted sources. Scan with VirusTotal before installing.',
            threatType: 'file',
            confidence: knownMalware ? 80 : 70,
            riskContext: RiskContext(
              appRole: 'Uninstalled APK File',
              installSourceLabel: 'File System',
              capabilityFlags: const ['UNINSTALLED_APK'],
            ),
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
              permissionsRequested: const [],
              recommendedAction:
                  'Archive contains suspicious content. Delete or scan before extracting.',
              threatType: 'file',
              confidence: 85,
              riskContext: RiskContext(
                appRole: 'Suspicious Archive',
                installSourceLabel: 'File System',
                capabilityFlags: const ['SUSPICIOUS_ARCHIVE'],
              ),
            ),
          );
        }
      }
    }

    return threats;
  }

  /// Clear analysis cache between scan sessions.
  void clearCache() {
    _analysisCache.clear();
    _reputation.clearCache();
  }
}
