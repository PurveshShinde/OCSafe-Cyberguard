import 'package:ocsafe_cyberguard/models/app_features.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';

/// A scored reason with severity tag for richer threat explanations.
class ScoredReason {
  final String reason;
  final String severity; // LOW, MEDIUM, HIGH
  final int points;

  const ScoredReason({
    required this.reason,
    required this.severity,
    required this.points,
  });

  @override
  String toString() => reason;
}

/// Centralized risk score output.
class RiskScore {
  final int score;
  final String riskLevel;
  final int confidence;
  final List<ScoredReason> scoredReasons;
  final List<String> flaggedPermissions;
  final String recommendedAction;

  const RiskScore({
    required this.score,
    required this.riskLevel,
    required this.confidence,
    required this.scoredReasons,
    required this.flaggedPermissions,
    required this.recommendedAction,
  });

  /// Convenience: plain reason strings for backward compatibility.
  List<String> get reasons => scoredReasons.map((r) => r.reason).toList();
}

/// Centralized risk scoring engine.
///
/// Replaces scattered scoring across ThreatAnalyzer and PermissionScanner
/// with a unified, context-aware pipeline:
///   Score = Base (install source) + Permission + Behavior + Stealth
///
/// Uses package name + app name + permissions combined for category-aware
/// permission scoring to drastically reduce false positives.
class RiskScoringEngine {
  static const List<String> _suspiciousKeywords = [
    'hack', 'spy', 'keylog', 'stealth', 'inject', 'exploit',
    'trojan', 'rat', 'backdoor', 'phish', 'spoof', 'crack',
    'bypass', 'fake', 'clone', 'adware', 'clicker',
  ];

  static const Map<String, String> _popularAppsWhitelist = {
    'whatsapp': 'com.whatsapp',
    'facebook': 'com.facebook.katana',
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
    'telegram': 'org.telegram.messenger',
    'spotify': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
  };

  /// Evaluate an app's risk based on extracted features.
  RiskScore evaluate(AppFeatures features) {
    final List<ScoredReason> reasons = [];
    int totalScore = 0;
    int signalCount = 0;
    int positiveSignals = 0;
    String recommendation = 'Review app usage if unfamiliar.';

    // ─── 1. Base Score (install source) ───────────────────────────────────
    signalCount++;
    if (features.isSideloaded) {
      totalScore += 15;
      reasons.add(const ScoredReason(
        reason: 'Application installed from unknown source (sideloaded)',
        severity: 'MEDIUM',
        points: 15,
      ));
      positiveSignals++;
    }

    // ─── 2. Permission Score (context-aware) ──────────────────────────────
    final permResult = _evaluatePermissions(features);
    totalScore += permResult.score;
    reasons.addAll(permResult.reasons);
    signalCount += permResult.signalsChecked;
    positiveSignals += permResult.positiveSignals;

    // ─── 3. Behavior Score ────────────────────────────────────────────────
    final behaviorResult = _evaluateBehavior(features);
    totalScore += behaviorResult.score;
    reasons.addAll(behaviorResult.reasons);
    signalCount += behaviorResult.signalsChecked;
    positiveSignals += behaviorResult.positiveSignals;

    // ─── 4. Stealth Score ─────────────────────────────────────────────────
    final stealthResult = _evaluateStealth(features);
    totalScore += stealthResult.score;
    reasons.addAll(stealthResult.reasons);
    signalCount += stealthResult.signalsChecked;
    positiveSignals += stealthResult.positiveSignals;

    // ─── Clamp & classify ─────────────────────────────────────────────────
    totalScore = totalScore.clamp(0, 100);

    final confidence = signalCount > 0
        ? ((positiveSignals / signalCount) * 100).round().clamp(0, 100)
        : 0;

    String riskLevel;
    if (totalScore >= 70) {
      riskLevel = 'HIGH';
      recommendation = 'High risk application detected. Consider uninstalling.';
    } else if (totalScore >= 35) {
      riskLevel = 'MEDIUM';
      recommendation = 'Review this application and its permissions carefully.';
    } else if (totalScore >= 15) {
      riskLevel = 'LOW';
    } else {
      riskLevel = 'SAFE';
    }

    return RiskScore(
      score: totalScore,
      riskLevel: riskLevel,
      confidence: confidence,
      scoredReasons: reasons,
      flaggedPermissions: _getFlaggedPermissions(features),
      recommendedAction: recommendation,
    );
  }

  // ─── Permission Scoring (Category-Aware) ──────────────────────────────

  _SubScore _evaluatePermissions(AppFeatures f) {
    final reasons = <ScoredReason>[];
    int score = 0;
    int signals = 0;
    int positive = 0;

    // Check each dangerous permission ONLY if unexpected for the category.
    // e.g. camera app + camera perm = expected → no points.
    // e.g. calculator + SMS perm = unexpected → HIGH severity.

    // ── Surveillance combo: Camera + Mic + Internet ──
    signals++;
    if (f.hasCameraPerm && f.hasMicPerm && f.hasInternetPerm) {
      final camExpected = f.isPermissionExpected('android.permission.CAMERA');
      final micExpected = f.isPermissionExpected('android.permission.RECORD_AUDIO');
      if (!camExpected || !micExpected) {
        score += 25;
        positive++;
        reasons.add(ScoredReason(
          reason:
              '${f.inferredCategory} app requests Camera + Microphone + Internet '
              '(possible surveillance)',
          severity: 'HIGH',
          points: 25,
        ));
      }
    }

    // ── Accessibility + Internet (banking malware pattern) ──
    signals++;
    if (f.hasAccessibilityPermission && f.hasInternetPerm) {
      score += 35;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Uses Accessibility Service with Internet access '
            '(common malware behavior)',
        severity: 'HIGH',
        points: 35,
      ));
    }

    // ── Overlay + Internet (phishing) ──
    signals++;
    if (f.hasOverlayPermission && f.hasInternetPerm) {
      score += 25;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Requests Screen Overlay + Internet '
            '(possible phishing or ad fraud)',
        severity: 'HIGH',
        points: 25,
      ));
    }

    // ── SMS + Internet (fraud) — only if SMS is unexpected for category ──
    signals++;
    if (f.hasSmsPerm && f.hasInternetPerm) {
      final smsExpected = f.isPermissionExpected('android.permission.READ_SMS');
      if (!smsExpected) {
        score += 25;
        positive++;
        reasons.add(ScoredReason(
          reason:
              '${f.inferredCategory} app requests SMS + Internet '
              '(unexpected — potential SMS fraud)',
          severity: 'HIGH',
          points: 25,
        ));
      }
    }

    // ── Contacts + Internet (data exfiltration) — only if unexpected ──
    signals++;
    if (f.hasContactsPerm && f.hasInternetPerm) {
      final expected =
          f.isPermissionExpected('android.permission.READ_CONTACTS');
      if (!expected) {
        score += 20;
        positive++;
        reasons.add(ScoredReason(
          reason:
              '${f.inferredCategory} app requests Contacts + Internet '
              '(unexpected — potential data exfiltration)',
          severity: 'MEDIUM',
          points: 20,
        ));
      }
    }

    // ── Location + Internet (tracking) — only if unexpected ──
    signals++;
    if (f.hasLocationPerm && f.hasInternetPerm) {
      final expected = f.isPermissionExpected(
          'android.permission.ACCESS_FINE_LOCATION');
      if (!expected) {
        score += 15;
        positive++;
        reasons.add(ScoredReason(
          reason:
              '${f.inferredCategory} app requests Location + Internet '
              '(unexpected — possible tracking)',
          severity: 'MEDIUM',
          points: 15,
        ));
      }
    }

    return _SubScore(score, reasons, signals, positive);
  }

  // ─── Behavior Scoring ─────────────────────────────────────────────────

  _SubScore _evaluateBehavior(AppFeatures f) {
    final reasons = <ScoredReason>[];
    int score = 0;
    int signals = 0;
    int positive = 0;

    final pkgLower = f.packageName.toLowerCase();
    final nameLower = f.appName.toLowerCase();

    // ── Keyword detection (only for sideloaded) ──
    if (f.isSideloaded) {
      signals++;
      final hasSuspicious = _suspiciousKeywords.any(
        (k) => pkgLower.contains(k) || nameLower.contains(k),
      );
      if (hasSuspicious) {
        score += 20;
        positive++;
        reasons.add(const ScoredReason(
          reason: 'Suspicious keyword detected in app name or package',
          severity: 'MEDIUM',
          points: 20,
        ));
      }
    }

    // ── Fake app detection ──
    signals++;
    for (final entry in _popularAppsWhitelist.entries) {
      if (nameLower.contains(entry.key) &&
          f.packageName != entry.value) {
        score += 35;
        positive++;
        reasons.add(const ScoredReason(
          reason: 'Possible impersonation of popular application',
          severity: 'HIGH',
          points: 35,
        ));
        break;
      }
    }

    // ── Suspicious namespace ──
    signals++;
    if (ThreatIntel.hasSuspiciousNamespace(f.packageName)) {
      score += 15;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Suspicious namespace pattern detected',
        severity: 'MEDIUM',
        points: 15,
      ));
    }

    // ── Fake system pattern ──
    signals++;
    if (ThreatIntel.hasFakeSystemPattern(f.packageName)) {
      score += 20;
      positive++;
      reasons.add(const ScoredReason(
        reason: 'Fake system app pattern detected in package name',
        severity: 'HIGH',
        points: 20,
      ));
    }

    return _SubScore(score, reasons, signals, positive);
  }

  // ─── Stealth Scoring ──────────────────────────────────────────────────

  _SubScore _evaluateStealth(AppFeatures f) {
    final reasons = <ScoredReason>[];
    int score = 0;
    int signals = 0;
    int positive = 0;

    // Only evaluate stealth for hidden, non-system, sideloaded apps
    if (!f.isHiddenApp || f.isSystemApp || !f.isSideloaded) {
      return _SubScore(0, reasons, 1, 0);
    }

    // Skip known safe hidden packages
    if (ThreatIntel.isSafeHiddenPackage(f.packageName)) {
      return _SubScore(0, reasons, 1, 0);
    }

    // ── Accessibility + Internet (hidden) ──
    signals++;
    if (f.hasAccessibilityPermission && f.hasInternetPerm) {
      score += 25;
      positive++;
    }

    // ── Overlay + Boot + Internet (hidden) ──
    signals++;
    if (f.hasOverlayPermission && f.hasBootPerm && f.hasInternetPerm) {
      score += 25;
      positive++;
    }

    // ── Foreground service + Wake lock (persistence) ──
    signals++;
    if (f.hasForegroundServicePerm && f.hasWakeLockPerm) {
      score += 10;
      positive++;
    }

    if (score > 0) {
      reasons.add(ScoredReason(
        reason: 'Hidden/stealth application with suspicious persistence '
            'capabilities',
        severity: 'HIGH',
        points: score,
      ));
    }

    return _SubScore(score, reasons, signals, positive);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

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

/// Internal sub-score result for each scoring component.
class _SubScore {
  final int score;
  final List<ScoredReason> reasons;
  final int signalsChecked;
  final int positiveSignals;

  const _SubScore(
      this.score, this.reasons, this.signalsChecked, this.positiveSignals);
}
