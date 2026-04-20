import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';

/// Result of a stealth detection evaluation.
class StealthProfile {
  /// True if the app shows clear stealth/hidden-process characteristics.
  final bool isStealth;

  /// Numeric stealth score (used by the risk engine for weighting).
  final int stealthScore;

  /// Human-readable labels for the detected stealth patterns.
  final List<String> detectedPatterns;

  const StealthProfile({
    required this.isStealth,
    required this.stealthScore,
    required this.detectedPatterns,
  });

  static const StealthProfile clean = StealthProfile(
    isStealth: false,
    stealthScore: 0,
    detectedPatterns: [],
  );
}

/// Upgraded stealth and hidden-app detection layer.
///
/// Detects apps that:
///   - Have no launcher icon (background-only)
///   - Are sideloaded / ADB-installed
///   - Have dangerous network + permission combos
///   - Have persistent execution capabilities
///
/// v2 improvements:
///   - Background-only + network + sensitive perm combo (new)
///   - No UI + Write Storage + Internet = dropper pattern (new)
///   - Significantly higher stealth scoring weight
///   - Returns structured [StealthProfile] instead of a bool
class StealthAppDetector {
  static final Map<String, StealthProfile> _cache = {};

  /// Trusted system namespaces — never flagged as stealth.
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

  /// Fake system naming patterns.
  static const List<String> _fakeSystemPatterns = [
    'android.system',
    'system.update',
    'google.security',
    'android.service',
    'system.service',
    'android.security.patch',
  ];

  static bool _isTrustedNamespace(String packageName) {
    for (final ns in _trustedNamespaces) {
      if (packageName.startsWith(ns)) return true;
    }
    return false;
  }

  static bool _isFromTrustedSource(AppInfo app) {
    if (app.installSource == null) return false;
    return app.installSource!.contains('android.vending') ||
        app.installSource == 'play_store' ||
        app.installSource!.contains('samsungapps') ||
        app.installSource!.contains('mipicks') ||
        app.installSource!.contains('appmarket') ||
        app.installSource!.contains('venezia');
  }

  static bool _isSideloaded(AppInfo app) {
    if (app.isSystemApp) return false;
    if (_isFromTrustedSource(app)) return false;
    return true;
  }

  static bool _hasFakeSystemPattern(String package) {
    final lower = package.toLowerCase();
    for (final pattern in _fakeSystemPatterns) {
      if (lower.contains(pattern)) return true;
    }
    return false;
  }

  /// Evaluate the stealth profile for [app].
  ///
  /// Returns a [StealthProfile] with a numeric score and pattern labels.
  /// The old [isStealthApp] boolean is available as [StealthProfile.isStealth].
  static StealthProfile evaluate(AppInfo app) {
    if (_cache.containsKey(app.packageName)) {
      return _cache[app.packageName]!;
    }

    final result = _evaluate(app);
    _cache[app.packageName] = result;
    return result;
  }

  /// Convenience boolean check (backward compatibility).
  static bool isStealthApp(AppInfo app) => evaluate(app).isStealth;

  static StealthProfile _evaluate(AppInfo app) {
    // ── Pre-filter: visible apps are not stealth (by definition) ──────────
    if (app.hasLaunchIntent) return StealthProfile.clean;

    // ── Pre-filter: system apps ────────────────────────────────────────────
    if (app.isSystemApp) return StealthProfile.clean;

    // ── Pre-filter: trusted OEM namespaces ────────────────────────────────
    if (_isTrustedNamespace(app.packageName)) return StealthProfile.clean;

    // ── Pre-filter: known safe hidden packages ────────────────────────────
    if (ThreatIntel.isSafeHiddenPackage(app.packageName)) {
      return StealthProfile.clean;
    }

    // ── Only evaluate sideloaded apps ─────────────────────────────────────
    if (!_isSideloaded(app)) return StealthProfile.clean;

    final perms = app.requestedPermissions.toSet();
    final patterns = <String>[];
    int score = 0;

    final hasAccessibility =
        perms.contains('android.permission.BIND_ACCESSIBILITY_SERVICE');
    final hasOverlay = perms.contains('android.permission.SYSTEM_ALERT_WINDOW');
    final hasBoot = perms.contains('android.permission.RECEIVE_BOOT_COMPLETED');
    final hasInternet = perms.contains('android.permission.INTERNET');
    final hasForegroundService =
        perms.contains('android.permission.FOREGROUND_SERVICE');
    final hasWakeLock = perms.contains('android.permission.WAKE_LOCK');
    final hasWriteStorage =
        perms.contains('android.permission.WRITE_EXTERNAL_STORAGE') ||
        perms.contains('android.permission.MANAGE_EXTERNAL_STORAGE');
    final hasCamera = perms.contains('android.permission.CAMERA');
    final hasMic = perms.contains('android.permission.RECORD_AUDIO');
    final hasSms = perms.contains('android.permission.READ_SMS') ||
        perms.contains('android.permission.SEND_SMS');
    final hasContacts = perms.contains('android.permission.READ_CONTACTS');
    final hasInstallPkgs =
        perms.contains('android.permission.REQUEST_INSTALL_PACKAGES');

    // ── Pattern 1: Background-only + network + sensitive perm (new) ───────
    // Classic spyware profile
    if (hasInternet &&
        (hasAccessibility || hasOverlay || hasSms || hasCamera || hasMic)) {
      score += 40;
      patterns.add(
          'Hidden app with Internet + sensitive permissions (spyware profile)');
    }

    // ── Pattern 2: No UI + Write + Internet = dropper (new) ───────────────
    if (hasInternet && hasWriteStorage) {
      score += 30;
      patterns.add(
          'Hidden app with Internet + file-write (dropper/downloader profile)');
    }

    // ── Pattern 3: Installer capability while hidden ───────────────────────
    if (hasInstallPkgs && hasInternet) {
      score += 35;
      patterns.add('Hidden installer — can silently install other APKs');
    }

    // ── Pattern 4: Accessibility + Internet (keylogger / banking malware) ─
    if (hasAccessibility && hasInternet) {
      score += 25;
      patterns.add('Hidden Accessibility Service with Internet (keylogger/banking malware)');
    }

    // ── Pattern 5: Overlay + Boot + Internet (phishing persistence) ───────
    if (hasOverlay && hasBoot && hasInternet) {
      score += 25;
      patterns.add('Hidden overlay + boot persistence (phishing app)');
    }

    // ── Pattern 6: Silent persistor (FG service + wake lock) ──────────────
    if (hasForegroundService && hasWakeLock) {
      score += 15;
      patterns.add('Silent persistent service with wake lock');
    }

    // ── Pattern 7: Fake system naming ─────────────────────────────────────
    if (_hasFakeSystemPattern(app.packageName)) {
      score += 15;
      patterns.add('Fake system app naming pattern: ${app.packageName}');
    }

    // ── Pattern 8: Suspicious namespace ───────────────────────────────────
    if (ThreatIntel.hasSuspiciousNamespace(app.packageName)) {
      score += 10;
      patterns.add('Suspicious namespace: ${app.packageName}');
    }

    // ── Pattern 9: Contacts exfil ─────────────────────────────────────────
    if (hasContacts && hasInternet) {
      score += 10;
      patterns.add('Hidden app reading contacts with Internet access');
    }

    // Threshold: score >= 30 = confirmed stealth
    final isStealth = score >= 30;

    return StealthProfile(
      isStealth: isStealth,
      stealthScore: score,
      detectedPatterns: patterns,
    );
  }

  /// Clear the detection cache between scan sessions.
  static void clearCache() => _cache.clear();
}
