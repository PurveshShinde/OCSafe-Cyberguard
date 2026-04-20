import 'package:ocsafe_cyberguard/models/app_features.dart';

/// The set of high-risk capabilities detected on an app.
class CapabilityProfile {
  /// App can install other APKs — primary installer detection.
  final bool canInstallApps;

  /// App has device administrator rights.
  final bool isDeviceAdmin;

  /// App has Accessibility Service binding.
  final bool hasAccessibility;

  /// App can draw over other apps (SYSTEM_ALERT_WINDOW).
  final bool hasOverlay;

  /// App starts on device boot.
  final bool hasBoot;

  /// App can read installed package usage statistics.
  final bool hasUsageStats;

  /// App can read system logs (admin-level information access).
  final bool hasReadLogs;

  /// App runs as a persistent foreground service.
  final bool hasForegroundService;

  /// App holds a wake lock (prevents CPU sleep).
  final bool hasWakeLock;

  /// Pre-computed raw capability risk score (before multipliers).
  final int capabilityRiskScore;

  /// Human-readable labels for active capabilities (shown in RiskContext).
  final List<String> activeFlags;

  const CapabilityProfile({
    required this.canInstallApps,
    required this.isDeviceAdmin,
    required this.hasAccessibility,
    required this.hasOverlay,
    required this.hasBoot,
    required this.hasUsageStats,
    required this.hasReadLogs,
    required this.hasForegroundService,
    required this.hasWakeLock,
    required this.capabilityRiskScore,
    required this.activeFlags,
  });
}

/// Dedicated capability detection layer.
///
/// Riskware patterns matched:
///   Android.Riskware.Install.Download  — INSTALL_PACKAGES + INTERNET
///   Android.Riskware.Adware            — OVERLAY + INTERNET
///   Android.Banker / Android.SpyAgent  — ACCESSIBILITY + INTERNET
///   Android.Backdoor                   — DEVICE_ADMIN
///
/// Install source is used as CONTEXT (multiplier amplifier), NOT as a base
/// score. A Play Store app with dangerous capabilities is still flagged.
class CapabilityAnalyzer {
  /// Analyze capability risk from extracted [AppFeatures].
  CapabilityProfile analyze(AppFeatures f) {
    final flags = <String>[];
    int score = 0;

    // ══════════════════════════════════════════════════════════════════════
    // RISKWARE: Android.Riskware.Install.Download (BitDefender classification)
    //
    // Pattern: REQUEST_INSTALL_PACKAGES + INTERNET
    //   → App can autonomously DOWNLOAD an APK from the internet
    //     AND INSTALL it without user going to Play Store.
    //   → This is flagged by OnePlus Phone Manager, Avast, ESET, BitDefender.
    //   → Flagged regardless of install source (Play Store apps too).
    //
    // Severity tiers:
    //   INSTALL + INTERNET + Hidden (no UI)  → CRITICAL dropper (+55)
    //   INSTALL + INTERNET + Sideloaded      → HIGH riskware (+45)
    //   INSTALL + INTERNET + Play Store      → MEDIUM riskware (+35)
    //   INSTALL alone (no internet)          → LOW informational (+15)
    // ══════════════════════════════════════════════════════════════════════
    if (f.hasInstallPackagesPerm) {
      if (f.hasInternetPerm) {
        // INSTALL + INTERNET = Riskware
        if (f.isHiddenApp && f.isSideloaded) {
          // Worst case: hidden dropper with no UI, sideloaded, can download+install
          flags.add('RISKWARE_INSTALL_DOWNLOAD_CRITICAL');
          score += 55;
        } else if (f.isSideloaded) {
          // Sideloaded installer + internet = Riskware (Third-party app store)
          flags.add('RISKWARE_THIRD_PARTY_STORE');
          score += 45;
        } else {
          // Play Store / OEM store app with install+download capability
          // Give it a safe score (10) so it is NOT flagged just for having this functionality
          // (fixes false positives for WhatsApp, Telegram, Brave Browser, etc.)
          flags.add('RISKWARE_INSTALL_DOWNLOAD');
          score += 10;
        }
      } else {
        // INSTALL without INTERNET = informational, can't auto-download
        flags.add('CAN_INSTALL_APPS');
        score += 15;
      }
    }

    // ══════════════════════════════════════════════════════════════════════
    // RISKWARE: Android.Riskware.Adware (OVERLAY + INTERNET)
    //   → App can draw popup ads over any other app while connected
    //   → Core adware pattern
    // ══════════════════════════════════════════════════════════════════════
    if (f.hasOverlayPermission && f.hasInternetPerm) {
      if (f.hasBootPerm) {
        // Persistent adware: survives reboots
        flags.add('RISKWARE_ADWARE_PERSISTENT');
        score += 45;
      } else {
        // Basic adware pattern
        flags.add('RISKWARE_ADWARE');
        score += 35;
      }
    }

    // ══════════════════════════════════════════════════════════════════════
    // THREAT: Android.Banker / Android.SpyAgent
    //   ACCESSIBILITY + INTERNET = keylogger / banking malware pattern
    // ══════════════════════════════════════════════════════════════════════
    if (f.hasAccessibilityPermission && f.hasInternetPerm) {
      flags.add('ACCESSIBILITY_ABUSE');
      score += 40;
    }

    // ══════════════════════════════════════════════════════════════════════
    // THREAT: Android.Backdoor — Device Admin privileges
    // ══════════════════════════════════════════════════════════════════════
    if (f.hasDeviceAdminPerm) {
      flags.add('DEVICE_ADMIN');
      score += 30;
    }

    // ── Usage stats + Internet — data snooping ────────────────────────────
    if (f.hasUsageStatsPerm && f.hasInternetPerm) {
      flags.add('USAGE_STATS_EXFIL');
      score += 25;
    }

    // ── Log read + Internet — log exfiltration ────────────────────────────
    if (f.hasReadLogsPerm && f.hasInternetPerm) {
      flags.add('LOG_EXFIL');
      score += 20;
    }

    // ── Silent persistent service (hidden app only) ───────────────────────
    if (f.hasForegroundServicePerm && f.hasWakeLockPerm && f.isHiddenApp) {
      flags.add('HIDDEN_PERSISTENT_SERVICE');
      score += 20;
    }

    return CapabilityProfile(
      canInstallApps: f.hasInstallPackagesPerm,
      isDeviceAdmin: f.hasDeviceAdminPerm,
      hasAccessibility: f.hasAccessibilityPermission,
      hasOverlay: f.hasOverlayPermission,
      hasBoot: f.hasBootPerm,
      hasUsageStats: f.hasUsageStatsPerm,
      hasReadLogs: f.hasReadLogsPerm,
      hasForegroundService: f.hasForegroundServicePerm,
      hasWakeLock: f.hasWakeLockPerm,
      capabilityRiskScore: score,
      activeFlags: flags,
    );
  }
}
