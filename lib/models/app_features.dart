import 'package:ocsafe_cyberguard/models/app_info.dart';

/// Structured feature extraction layer for intelligent threat analysis.
///
/// Extracts all relevant signals from an [AppInfo] into a flat, analysable
/// structure. Category inference uses package name + app name + permissions
/// together (not permissions alone) to reduce false positives.
class AppFeatures {
  final String appName;
  final String packageName;
  final bool isPlayStoreApp;
  final bool isSideloaded;
  final bool isSystemApp;
  final int dangerousPermissionCount;
  final bool hasOverlayPermission;
  final bool hasAccessibilityPermission;
  final bool hasSmsPerm;
  final bool hasCameraPerm;
  final bool hasMicPerm;
  final bool hasLocationPerm;
  final bool hasContactsPerm;
  final bool hasInternetPerm;
  final bool hasBootPerm;
  final bool hasForegroundServicePerm;
  final bool hasWakeLockPerm;
  final bool isHiddenApp;
  final bool isUnknownSource;
  final String inferredCategory;
  final List<String> requestedPermissions;

  const AppFeatures({
    required this.appName,
    required this.packageName,
    required this.isPlayStoreApp,
    required this.isSideloaded,
    required this.isSystemApp,
    required this.dangerousPermissionCount,
    required this.hasOverlayPermission,
    required this.hasAccessibilityPermission,
    required this.hasSmsPerm,
    required this.hasCameraPerm,
    required this.hasMicPerm,
    required this.hasLocationPerm,
    required this.hasContactsPerm,
    required this.hasInternetPerm,
    required this.hasBootPerm,
    required this.hasForegroundServicePerm,
    required this.hasWakeLockPerm,
    required this.isHiddenApp,
    required this.isUnknownSource,
    required this.inferredCategory,
    required this.requestedPermissions,
  });

  /// Dangerous permissions commonly abused by malware.
  static const Set<String> dangerousPermissions = {
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_SMS',
    'android.permission.SEND_SMS',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'android.permission.BIND_DEVICE_ADMIN',
  };

  /// Extract features from an [AppInfo] instance.
  factory AppFeatures.fromAppInfo(AppInfo app) {
    final perms = app.requestedPermissions.toSet();

    final hasCam = perms.contains('android.permission.CAMERA');
    final hasMic = perms.contains('android.permission.RECORD_AUDIO');
    final hasSms = perms.contains('android.permission.READ_SMS') ||
        perms.contains('android.permission.SEND_SMS');
    final hasLoc = perms.contains('android.permission.ACCESS_FINE_LOCATION') ||
        perms.contains('android.permission.ACCESS_COARSE_LOCATION');
    final hasContacts = perms.contains('android.permission.READ_CONTACTS');
    final hasOverlay = perms.contains('android.permission.SYSTEM_ALERT_WINDOW');
    final hasAccessibility =
        perms.contains('android.permission.BIND_ACCESSIBILITY_SERVICE');
    final hasInternet = perms.contains('android.permission.INTERNET');
    final hasBoot =
        perms.contains('android.permission.RECEIVE_BOOT_COMPLETED');
    final hasFgService =
        perms.contains('android.permission.FOREGROUND_SERVICE');
    final hasWakeLock = perms.contains('android.permission.WAKE_LOCK');

    final dangerousCount =
        perms.where((p) => dangerousPermissions.contains(p)).length;

    final isSideloaded = _isSideloaded(app.installSource) && !app.isSystemApp;
    final isPlayStore = !isSideloaded && !app.isSystemApp;

    final category = _inferCategory(
      app.packageName,
      app.appName,
      hasCam: hasCam,
      hasMic: hasMic,
      hasSms: hasSms,
      hasLoc: hasLoc,
      hasContacts: hasContacts,
    );

    return AppFeatures(
      appName: app.appName,
      packageName: app.packageName,
      isPlayStoreApp: isPlayStore,
      isSideloaded: isSideloaded,
      isSystemApp: app.isSystemApp,
      dangerousPermissionCount: dangerousCount,
      hasOverlayPermission: hasOverlay,
      hasAccessibilityPermission: hasAccessibility,
      hasSmsPerm: hasSms,
      hasCameraPerm: hasCam,
      hasMicPerm: hasMic,
      hasLocationPerm: hasLoc,
      hasContactsPerm: hasContacts,
      hasInternetPerm: hasInternet,
      hasBootPerm: hasBoot,
      hasForegroundServicePerm: hasFgService,
      hasWakeLockPerm: hasWakeLock,
      isHiddenApp: !app.hasLaunchIntent,
      isUnknownSource: isSideloaded,
      inferredCategory: category,
      requestedPermissions: app.requestedPermissions,
    );
  }

  static bool _isSideloaded(String? installer) {
    if (installer == null) return false; // IMPORTANT

    return ![
      'com.android.vending', // Play Store
      'play_store',
      'com.google.android.packageinstaller',
      'com.android.packageinstaller',
    ].contains(installer);
  }

  /// Infer app category from **package name + app name + permissions**.
  ///
  /// This is the key improvement over permissions-only inference.
  /// A calculator requesting SMS is suspicious; a camera app requesting
  /// camera permission is expected.
  static String _inferCategory(
    String packageName,
    String appName, {
    required bool hasCam,
    required bool hasMic,
    required bool hasSms,
    required bool hasLoc,
    required bool hasContacts,
  }) {
    final pkgLower = packageName.toLowerCase();
    final nameLower = appName.toLowerCase();

    // ── Name/package-based category (highest confidence) ──
    if (_matchesAny(pkgLower, nameLower, [
      'camera',
      'photo',
      'video',
      'gallery',
      'recorder',
      'snap',
    ])) {
      return 'media';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'calculator',
      'calc',
      'math',
      'converter',
      'unit',
    ])) {
      return 'utility';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'messenger',
      'chat',
      'whatsapp',
      'telegram',
      'signal',
      'sms',
      'message',
    ])) {
      return 'communication';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'map',
      'navigation',
      'gps',
      'uber',
      'lyft',
      'taxi',
      'travel',
    ])) {
      return 'navigation';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'bank',
      'pay',
      'wallet',
      'finance',
      'money',
      'upi',
    ])) {
      return 'finance';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'game',
      'play',
      'puzzle',
      'arcade',
      'racing',
    ])) {
      return 'game';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'social',
      'facebook',
      'instagram',
      'twitter',
      'tiktok',
      'reddit',
    ])) {
      return 'social';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'flashlight',
      'torch',
      'clock',
      'alarm',
      'weather',
      'note',
      'todo',
    ])) {
      return 'utility';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'browser',
      'chrome',
      'firefox',
      'web',
    ])) {
      return 'browser';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'music',
      'audio',
      'spotify',
      'podcast',
      'radio',
    ])) {
      return 'media';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'file',
      'manager',
      'explorer',
      'storage',
    ])) {
      return 'filemanager';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'mail',
      'email',
      'gmail',
      'outlook',
    ])) {
      return 'communication';
    }
    if (_matchesAny(pkgLower, nameLower, [
      'dialer',
      'phone',
      'call',
      'contacts',
    ])) {
      return 'communication';
    }

    // ── Permission-based fallback (lower confidence) ──
    if (hasCam && hasMic) return 'media';
    if (hasSms && hasContacts) return 'communication';
    if (hasLoc) return 'navigation';

    return 'unknown';
  }

  static bool _matchesAny(
    String pkgLower,
    String nameLower,
    List<String> keywords,
  ) {
    return keywords.any(
      (k) => pkgLower.contains(k) || nameLower.contains(k),
    );
  }

  /// Returns true if the given permission is EXPECTED for this app's category.
  bool isPermissionExpected(String permission) {
    switch (inferredCategory) {
      case 'media':
        if (permission == 'android.permission.CAMERA' ||
            permission == 'android.permission.RECORD_AUDIO') return true;
        break;
      case 'communication':
        if (permission == 'android.permission.READ_SMS' ||
            permission == 'android.permission.SEND_SMS' ||
            permission == 'android.permission.READ_CONTACTS') return true;
        break;
      case 'navigation':
        if (permission == 'android.permission.ACCESS_FINE_LOCATION' ||
            permission == 'android.permission.ACCESS_COARSE_LOCATION') {
          return true;
        }
        break;
      case 'social':
        if (permission == 'android.permission.CAMERA' ||
            permission == 'android.permission.ACCESS_FINE_LOCATION' ||
            permission == 'android.permission.READ_CONTACTS') return true;
        break;
      case 'browser':
        if (permission == 'android.permission.ACCESS_FINE_LOCATION')
          return true;
        break;
      case 'filemanager':
        // No dangerous perms expected beyond storage (which isn't in our list)
        break;
      case 'finance':
        // Camera for check deposit, SMS for OTP
        if (permission == 'android.permission.CAMERA' ||
            permission == 'android.permission.READ_SMS') return true;
        break;
    }
    return false;
  }
}
