import 'package:ocsafe_cyberguard/models/app_features.dart';
import 'package:ocsafe_cyberguard/models/app_role.dart';
import 'package:ocsafe_cyberguard/services/capability_analyzer.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';

// ─── Scored reason model ────────────────────────────────────────────────────

/// A scored reason with severity tag for richer threat explanations.
class ScoredReason {
  final String reason;
  final String severity; // LOW, MEDIUM, HIGH, CRITICAL
  final int points;

  const ScoredReason({
    required this.reason,
    required this.severity,
    required this.points,
  });

  @override
  String toString() => reason;
}

// ─── Risk score output ──────────────────────────────────────────────────────

/// Centralized risk score output.
///
/// [score]      — severity of the threat (0–100). Drives riskLevel.
/// [confidence] — certainty of the detection (0–100). Separate from score.
class RiskScore {
  final int score;
  final String riskLevel;
  final int confidence;
  final List<ScoredReason> scoredReasons;
  final List<String> flaggedPermissions;
  final List<String> capabilityFlags;
  final String recommendedAction;
  final bool overrideApplied;

  const RiskScore({
    required this.score,
    required this.riskLevel,
    required this.confidence,
    required this.scoredReasons,
    required this.flaggedPermissions,
    required this.capabilityFlags,
    required this.recommendedAction,
    this.overrideApplied = false,
  });

  /// Convenience: plain reason strings for backward compatibility.
  List<String> get reasons => scoredReasons.map((r) => r.reason).toList();
}

// ─── Sub-score helper ───────────────────────────────────────────────────────

class _SubScore {
  final int score;
  final List<ScoredReason> reasons;
  final int signalsChecked;
  final int positiveSignals;

  const _SubScore(
      this.score, this.reasons, this.signalsChecked, this.positiveSignals);
}

// ─── Main Engine ────────────────────────────────────────────────────────────

/// Behavior-driven risk scoring engine.
///
/// CORE PRINCIPLE: Detection is based on INTENT (behavior), NOT ORIGIN (source).
///
/// An app is NEVER flagged just because it's sideloaded. Install source is used
/// only as CONTEXT to amplify behavioral signals via multipliers and overrides.
///
/// Pipeline:
///   1. Capability Analysis (installer, accessibility, overlay, device admin)
///   2. Behavior Pattern Detection (adware, privacy abuse, financial, dropper)
///   3. Context-Aware Permission Evaluation (category-aware combos)
///   4. Stealth Detection (hidden + network + perms)
///   5. Correlation Multipliers (install source amplifies behavioral signals)
///   6. Override Rules (critical combos force minimum scores)
///   7. Signal Gate (≥1 behavioral signal required to produce any output)
///   8. Adaptive Threshold Classification (per app role)
///
/// What does NOT score points:
///   - Being sideloaded alone
///   - Having only INTERNET permission
///   - Having permissions expected for the app's category
class RiskScoringEngine {
  final CapabilityAnalyzer _capabilityAnalyzer = CapabilityAnalyzer();

  // ── Popular apps whitelist (fake app detection) ──────────────────────────
  static const Map<String, String> _popularAppsWhitelist = {
    'whatsapp': 'com.whatsapp',
    'facebook': 'com.facebook.katana',
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
    'telegram': 'org.telegram.messenger',
    'spotify': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
    'snapchat': 'com.snapchat.android',
    'twitter': 'com.twitter.android',
    'tiktok': 'com.zhiliaoapp.musically',
  };

  // ── Suspicious keywords (minor signal only, sideloaded apps only) ────────
  static const List<String> _suspiciousKeywords = [
    'hack', 'spy', 'keylog', 'stealth', 'inject', 'exploit',
    'trojan', 'rat', 'backdoor', 'phish', 'spoof', 'crack',
    'bypass',
  ];

  // ─── Main evaluation entry point ────────────────────────────────────────

  /// Evaluate an app's risk based on extracted [AppFeatures].
  RiskScore evaluate(AppFeatures features) {
    final List<ScoredReason> reasons = [];
    int raw = 0;
    int signalCount = 0;
    int positiveSignals = 0;

    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║  NO INSTALL SOURCE BASE SCORE                                      ║
    // ║  Install source is CONTEXT ONLY — used in multipliers/overrides.   ║
    // ║  A clean sideloaded app with no behavioral signals = score 0.      ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    // ── Layer 1: Capability Analysis (installer, admin, accessibility) ────
    final capProfile = _capabilityAnalyzer.analyze(features);
    signalCount++;
    if (capProfile.capabilityRiskScore > 0) {
      raw += capProfile.capabilityRiskScore;
      positiveSignals++;

      // ── Android.Riskware.Install.Download / Third-Party Store detection ─────
      if (capProfile.activeFlags.contains('RISKWARE_INSTALL_DOWNLOAD_CRITICAL')) {
        reasons.add(const ScoredReason(
          reason: 'Android.Riskware.Install.Download [CRITICAL]: '
              'Hidden app with REQUEST_INSTALL_PACKAGES + Internet — '
              'can silently download and install APKs without user awareness',
          severity: 'HIGH',
          points: 55,
        ));
      } else if (capProfile.activeFlags.contains('RISKWARE_THIRD_PARTY_STORE')) {
        reasons.add(const ScoredReason(
          reason: 'Can install apps outside Play Store',
          severity: 'MEDIUM',
          points: 45,
        ));
      } else if (capProfile.activeFlags.contains('RISKWARE_INSTALL_DOWNLOAD')) {
        reasons.add(const ScoredReason(
          reason: 'Android.Riskware.Install.Download: '
              'This app has permission to install other applications AND '
              'internet access — it can autonomously download and deploy APKs',
          severity: 'MEDIUM',
          points: 35,
        ));
      } else if (capProfile.activeFlags.contains('CAN_INSTALL_APPS')) {
        // Install capability without internet — informational only
        reasons.add(const ScoredReason(
          reason: 'App can install other applications (REQUEST_INSTALL_PACKAGES)',
          severity: 'LOW',
          points: 15,
        ));
      }
      // ── Android.Riskware.Adware detection ────────────────────────────────
      if (capProfile.activeFlags.contains('RISKWARE_ADWARE_PERSISTENT')) {
        reasons.add(const ScoredReason(
          reason: 'Android.Riskware.Adware [Persistent]: '
              'Screen Overlay + Internet + Boot persistence — '
              'app can display ads/phishing overlays and survives reboots',
          severity: 'HIGH',
          points: 45,
        ));
      } else if (capProfile.activeFlags.contains('RISKWARE_ADWARE')) {
        reasons.add(const ScoredReason(
          reason: 'Android.Riskware.Adware: '
              'Screen Overlay permission + Internet — '
              'app can display popup ads or phishing screens over other apps',
          severity: 'MEDIUM',
          points: 35,
        ));
      }
      // ── Banking malware / keylogger ───────────────────────────────────────
      if (capProfile.hasAccessibility && features.hasInternetPerm) {
        reasons.add(const ScoredReason(
          reason: 'Android.Banker/SpyAgent pattern: '
              'Accessibility Service + Internet access — '
              'can read screen content and send data remotely (keylogger risk)',
          severity: 'HIGH',
          points: 40,
        ));
      }
      if (capProfile.isDeviceAdmin) {
        reasons.add(const ScoredReason(
          reason: 'Android.Backdoor: Device Administrator rights — '
              'can lock device, wipe data, or prevent uninstallation',
          severity: 'HIGH',
          points: 30,
        ));
      }
      if (capProfile.hasUsageStats && features.hasInternetPerm) {
        reasons.add(const ScoredReason(
          reason: 'Reads app usage statistics with Internet (data snooping)',
          severity: 'MEDIUM',
          points: 25,
        ));
      }
      if (capProfile.hasReadLogs && features.hasInternetPerm) {
        reasons.add(const ScoredReason(
          reason: 'Can read system logs with Internet (log exfiltration)',
          severity: 'MEDIUM',
          points: 20,
        ));
      }
    }

    // ── Layer 2: Behavior Pattern Detection ───────────────────────────────
    final behaviorResult = _evaluateBehavior(features);
    raw += behaviorResult.score;
    reasons.addAll(behaviorResult.reasons);
    signalCount += behaviorResult.signalsChecked;
    positiveSignals += behaviorResult.positiveSignals;

    // ── Layer 3: Context-Aware Permission Evaluation ─────────────────────
    final permResult = _evaluatePermissions(features);
    raw += permResult.score;
    reasons.addAll(permResult.reasons);
    signalCount += permResult.signalsChecked;
    positiveSignals += permResult.positiveSignals;

    // ── Layer 4: Stealth Detection ────────────────────────────────────────
    final stealthResult = _evaluateStealth(features);
    raw += stealthResult.score;
    reasons.addAll(stealthResult.reasons);
    signalCount += stealthResult.signalsChecked;
    positiveSignals += stealthResult.positiveSignals;

    // ── Layer 5: Correlation Multipliers ──────────────────────────────────
    // Install source ONLY affects scoring here — as an amplifier, not a base.
    raw = _applyMultipliers(raw, features, capProfile);

    // ── Layer 6: Override Rules ───────────────────────────────────────────
    // Critical combos force minimum scores regardless of heuristics.
    bool overrideApplied = false;
    final overrideResult = _applyOverrides(raw, features, capProfile);
    if (overrideResult > raw) {
      raw = overrideResult;
      overrideApplied = true;
    }

    // ── Layer 7: Signal Gate ──────────────────────────────────────────────
    // REQUIRE at least 1 behavioral signal to produce any output.
    // This prevents clean apps from being flagged.
    if (positiveSignals == 0 && !overrideApplied) {
      return const RiskScore(
        score: 0,
        riskLevel: 'SAFE',
        confidence: 0,
        scoredReasons: [],
        flaggedPermissions: [],
        capabilityFlags: [],
        recommendedAction: 'No suspicious behavior detected.',
      );
    }

    // ── Clamp ─────────────────────────────────────────────────────────────
    raw = raw.clamp(0, 100);

    // ── Confidence (separate from risk score) ─────────────────────────────
    final confidence = signalCount > 0
        ? ((positiveSignals / signalCount) * 100).round().clamp(0, 100)
        : 0;

    // ── Layer 8: Adaptive Threshold Classification ────────────────────────
    final thresholds = _getThresholds(features.appRole);
    String riskLevel;
    String recommendation;

    if (raw >= thresholds.high) {
      riskLevel = 'HIGH';
      recommendation =
          'This app may steal data or control your device. Uninstall immediately.';
    } else if (raw >= thresholds.medium) {
      riskLevel = 'MEDIUM';
      recommendation =
          'Suspicious behavior detected. Review this app and its permissions.';
    } else if (raw >= thresholds.low) {
      riskLevel = 'LOW';
      recommendation = 'Minor risk signals detected. Monitor this app.';
    } else {
      riskLevel = 'SAFE';
      recommendation = 'No suspicious behavior detected.';
    }

    // Riskware-specific recommendations
    if (capProfile.activeFlags.contains('RISKWARE_INSTALL_DOWNLOAD_CRITICAL')) {
      recommendation =
          'DANGEROUS: Android.Riskware.Install.Download detected. '
          'This hidden app can silently download and install malware. '
          'Uninstall immediately.';
    } else if (capProfile.activeFlags.contains('RISKWARE_THIRD_PARTY_STORE')) {
      recommendation =
          'This visible installer app can install other apps '
          'outside of the Play Store. Consider removing if unneeded.';
    } else if (capProfile.activeFlags.contains('RISKWARE_INSTALL_DOWNLOAD')) {
      recommendation =
          'Android.Riskware.Install.Download: This app can install '
          'other applications and has internet access. '
          'Review carefully before keeping.';
    }

    return RiskScore(
      score: raw,
      riskLevel: riskLevel,
      confidence: confidence,
      scoredReasons: reasons,
      flaggedPermissions: _getFlaggedPermissions(features),
      capabilityFlags: capProfile.activeFlags,
      recommendedAction: recommendation,
      overrideApplied: overrideApplied,
    );
  }

  // ─── Adaptive thresholds per AppRole ────────────────────────────────────

  _Thresholds _getThresholds(AppRole role) {
    switch (role) {
      case AppRole.installer:
        // Installers are inherently risky by capability
        return const _Thresholds(low: 15, medium: 35, high: 60);
      case AppRole.downloader:
        return const _Thresholds(low: 15, medium: 30, high: 55);
      case AppRole.backgroundService:
        return const _Thresholds(low: 15, medium: 30, high: 55);
      case AppRole.communication:
        // Communication apps legitimately need more permissions
        return const _Thresholds(low: 20, medium: 40, high: 70);
      case AppRole.uiApp:
      case AppRole.unknown:
        return const _Thresholds(low: 15, medium: 35, high: 70);
    }
  }

  // ─── Correlation Multipliers ─────────────────────────────────────────────

  /// Apply non-linear multipliers when dangerous combos + context align.
  /// Install source is used HERE as context amplifier — NOT as base score.
  int _applyMultipliers(
    int score,
    AppFeatures f,
    CapabilityProfile cap,
  ) {
    // No behavioral score = no multiplier needed
    if (score == 0) return 0;

    double multiplier = 1.0;

    // Accessibility + Overlay + Internet — phishing + keylogger combo
    if (cap.hasAccessibility && cap.hasOverlay && f.hasInternetPerm) {
      multiplier = multiplier < 1.5 ? 1.5 : multiplier;
    }

    // Installer + Sideloaded + No UI — dropper pattern
    // Install source as CONTEXT amplifier
    if (cap.canInstallApps && f.isSideloaded && f.isHiddenApp) {
      multiplier = multiplier < 2.0 ? 2.0 : multiplier;
    }

    // Fake app name + Sideloaded — impersonation combo
    if (_isFakeApp(f) && f.isSideloaded) {
      multiplier = multiplier < 1.8 ? 1.8 : multiplier;
    }

    // Device admin + Sideloaded — critical
    if (cap.isDeviceAdmin && f.isSideloaded) {
      multiplier = multiplier < 1.7 ? 1.7 : multiplier;
    }

    return (score * multiplier).round();
  }

  bool _isFakeApp(AppFeatures f) {
    final nameLower = f.appName.toLowerCase();
    for (final entry in _popularAppsWhitelist.entries) {
      if (nameLower.contains(entry.key) && f.packageName != entry.value) {
        return true;
      }
    }
    return false;
  }

  // ─── Override Rules ──────────────────────────────────────────────────────

  /// Returns the minimum score that should be enforced for critical combinations.
  /// These rules bypass normal scoring to force minimum risk classification.
  int _applyOverrides(int score, AppFeatures f, CapabilityProfile cap) {
    int minScore = score;

    // ── Android.Riskware.Install.Download — guaranteed MEDIUM ────────────
    // Any app with REQUEST_INSTALL_PACKAGES + INTERNET is riskware.
    if (cap.canInstallApps && f.hasInternetPerm) {
      if (f.isSideloaded && f.isHiddenApp) {
        minScore = minScore < 85 ? 85 : minScore; // Hidden dropper → HIGH
      } else if (f.isSideloaded) {
        minScore = minScore < 45 ? 45 : minScore; // Visible sideloaded installer → MEDIUM
      } else {
        minScore = minScore < 35 ? 35 : minScore; // Play Store installer → MEDIUM
      }
    }

    // ── Financial Threat Pattern ──────────────────────────────────────────
    // Accessibility + Overlay + Internet → ALWAYS HIGH
    if (cap.hasAccessibility && cap.hasOverlay && f.hasInternetPerm) {
      minScore = minScore < 75 ? 75 : minScore;
    }

    // ── Device Admin abuse ───────────────────────────────────────────────
    // Device admin + sideloaded → HIGH
    if (cap.isDeviceAdmin && f.isSideloaded) {
      minScore = minScore < 70 ? 70 : minScore;
    }

    // ── Hidden Accessibility abuse ───────────────────────────────────────
    // Hidden + Accessibility + Internet → HIGH
    if (f.isHiddenApp && cap.hasAccessibility && f.hasInternetPerm) {
      minScore = minScore < 72 ? 72 : minScore;
    }

    return minScore;
  }

  // ─── Layer 2: Behavior Pattern Detection ─────────────────────────────────

  _SubScore _evaluateBehavior(AppFeatures f) {
    final reasons = <ScoredReason>[];
    int score = 0;
    int signals = 0;
    int positive = 0;

    final pkgLower = f.packageName.toLowerCase();
    final nameLower = f.appName.toLowerCase();

    // ── Fake popular app detection (impersonation) ────────────────────────
    signals++;
    for (final entry in _popularAppsWhitelist.entries) {
      if (nameLower.contains(entry.key) && f.packageName != entry.value) {
        score += 40;
        positive++;
        reasons.add(ScoredReason(
          reason:
              'Possible impersonation of ${entry.key}. Actual package: ${f.packageName}',
          severity: 'HIGH',
          points: 40,
        ));
        break;
      }
    }

    // ── Suspicious keyword (MINOR signal, sideloaded only) ────────────────
    // Demoted: max +10, and only for sideloaded apps with the keyword
    // in the PACKAGE NAME (not app display name — too many false positives)
    if (f.isSideloaded) {
      signals++;
      final suspiciousKeyword =
          _suspiciousKeywords.cast<String?>().firstWhere(
                (k) => pkgLower.contains(k!),
                orElse: () => null,
              );
      if (suspiciousKeyword != null) {
        score += 10;
        positive++;
        reasons.add(ScoredReason(
          reason:
              'Suspicious keyword "$suspiciousKeyword" in package name (minor signal)',
          severity: 'LOW',
          points: 10,
        ));
      }
    }

    // ── Suspicious namespace pattern ──────────────────────────────────────
    signals++;
    if (ThreatIntel.hasSuspiciousNamespace(f.packageName)) {
      score += 20;
      positive++;
      reasons.add(ScoredReason(
        reason: 'Suspicious namespace pattern: ${f.packageName}',
        severity: 'MEDIUM',
        points: 20,
      ));
    }

    // ── Fake system app pattern ───────────────────────────────────────────
    signals++;
    if (ThreatIntel.hasFakeSystemPattern(f.packageName)) {
      score += 30;
      positive++;
      reasons.add(ScoredReason(
        reason: 'Fake system app naming pattern: ${f.packageName}',
        severity: 'HIGH',
        points: 30,
      ));
    }

    return _SubScore(score, reasons, signals, positive);
  }

  // ─── Layer 3: Context-Aware Permission Evaluation ────────────────────────

  _SubScore _evaluatePermissions(AppFeatures f) {
    final reasons = <ScoredReason>[];
    int score = 0;
    int signals = 0;
    int positive = 0;

    // ── Surveillance combo: Camera + Mic + Internet ──────────────────────
    // Only flagged if camera/mic is UNEXPECTED for the app's inferred category
    signals++;
    if (f.hasCameraPerm && f.hasMicPerm && f.hasInternetPerm) {
      final camExpected = f.isPermissionExpected('android.permission.CAMERA');
      final micExpected =
          f.isPermissionExpected('android.permission.RECORD_AUDIO');
      if (!camExpected || !micExpected) {
        score += 30;
        positive++;
        reasons.add(ScoredReason(
          reason: '${f.inferredCategory} app requests Camera + Microphone + '
              'Internet (possible surveillance)',
          severity: 'HIGH',
          points: 30,
        ));
      }
    }

    // ── Privacy Abuse: SMS + Internet (unexpected) ────────────────────────
    signals++;
    if (f.hasSmsPerm && f.hasInternetPerm) {
      if (!f.isPermissionExpected('android.permission.READ_SMS')) {
        score += 35;
        positive++;
        reasons.add(ScoredReason(
          reason: '${f.inferredCategory} app requests SMS + Internet '
              '(unexpected — potential SMS fraud or data harvesting)',
          severity: 'HIGH',
          points: 35,
        ));
      }
    }

    // ── Privacy Abuse: Contacts + Internet (unexpected) ──────────────────
    signals++;
    if (f.hasContactsPerm && f.hasInternetPerm) {
      if (!f.isPermissionExpected('android.permission.READ_CONTACTS')) {
        score += 30;
        positive++;
        reasons.add(ScoredReason(
          reason: '${f.inferredCategory} app requests Contacts + Internet '
              '(unexpected — potential data exfiltration)',
          severity: 'MEDIUM',
          points: 30,
        ));
      }
    }

    // ── Privacy Abuse: Location + Internet (unexpected) ──────────────────
    signals++;
    if (f.hasLocationPerm && f.hasInternetPerm) {
      if (!f.isPermissionExpected(
          'android.permission.ACCESS_FINE_LOCATION')) {
        score += 20;
        positive++;
        reasons.add(ScoredReason(
          reason: '${f.inferredCategory} app requests Location + Internet '
              '(unexpected — possible tracking)',
          severity: 'MEDIUM',
          points: 20,
        ));
      }
    }

    return _SubScore(score, reasons, signals, positive);
  }

  // ─── Layer 4: Stealth Detection ──────────────────────────────────────────

  _SubScore _evaluateStealth(AppFeatures f) {
    final reasons = <ScoredReason>[];
    int score = 0;
    int signals = 0;
    int positive = 0;

    // Only evaluate hidden (no launcher icon) apps
    if (!f.isHiddenApp) return _SubScore(0, reasons, 1, 0);
    if (f.isSystemApp) return _SubScore(0, reasons, 1, 0);
    if (ThreatIntel.isSafeHiddenPackage(f.packageName)) {
      return _SubScore(0, reasons, 1, 0);
    }

    // ── Background-only + network + sensitive permissions ─────────────────
    signals++;
    if (f.hasInternetPerm &&
        (f.hasAccessibilityPermission ||
            f.hasOverlayPermission ||
            f.hasSmsPerm ||
            f.hasCameraPerm ||
            f.hasMicPerm)) {
      score += 35;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Hidden app with Internet + sensitive permissions '
            '(stealth spyware profile)',
        severity: 'HIGH',
        points: 35,
      ));
    }

    // ── No UI + Internet + Write Storage (downloader / dropper) ──────────
    signals++;
    if (f.hasInternetPerm && f.hasWriteStoragePerm) {
      score += 30;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Hidden app with Internet + file write '
            '(dropper / downloader profile)',
        severity: 'HIGH',
        points: 30,
      ));
    }

    // ── ForegroundService + WakeLock (persistent hidden execution) ────────
    signals++;
    if (f.hasForegroundServicePerm && f.hasWakeLockPerm) {
      score += 15;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Hidden persistent service with wake lock '
            '(silent background execution)',
        severity: 'MEDIUM',
        points: 15,
      ));
    }

    // ── Boot persistence + hidden + sideloaded ───────────────────────────
    signals++;
    if (f.hasBootPerm && f.isSideloaded) {
      score += 15;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Hidden sideloaded app starts on device boot',
        severity: 'MEDIUM',
        points: 15,
      ));
    }

    return _SubScore(score, reasons, signals, positive);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  List<String> _getFlaggedPermissions(AppFeatures f) {
    final flagged = <String>[];
    for (final perm in f.requestedPermissions) {
      if (AppFeatures.dangerousPermissions.contains(perm) &&
          !f.isPermissionExpected(perm)) {
        flagged.add(perm);
      }
    }
    return flagged;
  }
}

// ─── Adaptive threshold container ────────────────────────────────────────────

class _Thresholds {
  final int low;
  final int medium;
  final int high;
  const _Thresholds({
    required this.low,
    required this.medium,
    required this.high,
  });
}
