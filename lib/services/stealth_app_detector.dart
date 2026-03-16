import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';

class StealthAppDetector {
  static final Map<String, bool> _cache = {};

  /// Trusted system namespaces
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

  /// Suspicious fake system patterns
  static const List<String> _fakeSystemPatterns = [
    'android.system',
    'system.update',
    'google.security',
    'android.service',
  ];

  static bool _isTrustedNamespace(String packageName) {
    for (final ns in _trustedNamespaces) {
      if (packageName.startsWith(ns)) {
        return true;
      }
    }
    return false;
  }

  static bool _isPlayStoreApp(AppInfo app) {
    if (app.installSource == null) return false;
    return app.installSource!.contains('android.vending');
  }

  static bool _isSideloaded(AppInfo app) {
    if (app.isSystemApp) return false;
    if (_isPlayStoreApp(app)) return false;
    return true;
  }

  static bool _hasFakeSystemPattern(String package) {
    final lower = package.toLowerCase();

    for (final pattern in _fakeSystemPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  static bool isStealthApp(AppInfo app) {
    if (_cache.containsKey(app.packageName)) {
      return _cache[app.packageName]!;
    }

    /// Step 1 — must be hidden
    if (app.hasLaunchIntent) {
      _cache[app.packageName] = false;
      return false;
    }

    /// Step 2 — skip system apps
    if (app.isSystemApp) {
      _cache[app.packageName] = false;
      return false;
    }

    /// Step 3 — trusted namespaces
    if (_isTrustedNamespace(app.packageName)) {
      _cache[app.packageName] = false;
      return false;
    }

    /// Step 4 — known safe hidden packages
    if (ThreatIntel.isSafeHiddenPackage(app.packageName)) {
      _cache[app.packageName] = false;
      return false;
    }

    /// Step 5 — evaluate only sideloaded apps
    if (!_isSideloaded(app)) {
      _cache[app.packageName] = false;
      return false;
    }

    final perms = app.requestedPermissions.toSet();

    final hasAccessibility = perms.contains(
      'android.permission.BIND_ACCESSIBILITY_SERVICE',
    );

    final hasOverlay = perms.contains('android.permission.SYSTEM_ALERT_WINDOW');

    final hasBoot = perms.contains('android.permission.RECEIVE_BOOT_COMPLETED');

    final hasInternet = perms.contains('android.permission.INTERNET');

    final hasForegroundService = perms.contains(
      'android.permission.FOREGROUND_SERVICE',
    );

    final hasWakeLock = perms.contains('android.permission.WAKE_LOCK');

    final hasSuspiciousNamespace = ThreatIntel.hasSuspiciousNamespace(
      app.packageName,
    );

    final hasFakeSystemName = _hasFakeSystemPattern(app.packageName);

    int suspiciousScore = 0;

    if (hasAccessibility && hasInternet) suspiciousScore += 2;
    if (hasOverlay && hasBoot && hasInternet) suspiciousScore += 2;
    if (hasForegroundService && hasWakeLock) suspiciousScore += 1;
    if (hasSuspiciousNamespace) suspiciousScore += 1;
    if (hasFakeSystemName) suspiciousScore += 1;

    final result = suspiciousScore >= 2;

    _cache[app.packageName] = result;
    return result;
  }
}
