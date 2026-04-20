import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/app_role.dart';

/// Structured feature extraction layer for intelligent threat analysis.
///
/// Extracts all relevant signals from an [AppInfo] into a flat, analysable
/// structure. Role inference uses package name + app name + permission
/// behavior together (NOT keywords alone) to reduce false positives.
///
/// New in v2:
/// - [appRole]         : behavior-based functional role (installer, service, etc.)
/// - [installSourceTier]: tiered install source instead of binary sideload flag
/// - [hasInstallPackagesPerm]: critical capability — can install other APKs
/// - [hasDeviceAdminPerm]: device administrator — high privilege
/// - [hasUsageStatsPerm]: can read app usage data
/// - [hasReadLogsPerm]: can read system logs
class AppFeatures {
  final String appName;
  final String packageName;
  final bool isPlayStoreApp;
  final bool isSideloaded;
  final bool isSystemApp;
  final int dangerousPermissionCount;

  // ── Standard permission flags ──────────────────────────────────────────
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

  // ── New capability flags ───────────────────────────────────────────────
  /// App can install other APKs (`REQUEST_INSTALL_PACKAGES`)
  final bool hasInstallPackagesPerm;

  /// App has device admin rights (`BIND_DEVICE_ADMIN`)
  final bool hasDeviceAdminPerm;

  /// App can read usage stats (`PACKAGE_USAGE_STATS`)
  final bool hasUsageStatsPerm;

  /// App can read system logs (`READ_LOGS`)
  final bool hasReadLogsPerm;

  /// App has write external storage capability
  final bool hasWriteStoragePerm;

  // ── Role & source classification ──────────────────────────────────────
  final bool isHiddenApp;
  final bool isUnknownSource;

  /// Behavior-based app role — NOT keyword based
  final AppRole appRole;

  /// Tiered install source with dynamic risk weight
  final InstallSourceTier installSourceTier;

  /// Inferred app category (media, utility, communication, etc.)
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
    required this.hasInstallPackagesPerm,
    required this.hasDeviceAdminPerm,
    required this.hasUsageStatsPerm,
    required this.hasReadLogsPerm,
    required this.hasWriteStoragePerm,
    required this.isHiddenApp,
    required this.isUnknownSource,
    required this.appRole,
    required this.installSourceTier,
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
    'android.permission.REQUEST_INSTALL_PACKAGES',
    'android.permission.PACKAGE_USAGE_STATS',
    'android.permission.READ_LOGS',
  };

  /// Extract features from an [AppInfo] instance.
  factory AppFeatures.fromAppInfo(AppInfo app) {
    final perms = app.requestedPermissions.toSet();

    // ── Permission flags ─────────────────────────────────────────────────
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

    // ── New capability flags ──────────────────────────────────────────────
    final hasInstallPkgs =
        perms.contains('android.permission.REQUEST_INSTALL_PACKAGES');
    final hasDevAdmin =
        perms.contains('android.permission.BIND_DEVICE_ADMIN');
    final hasUsageStats =
        perms.contains('android.permission.PACKAGE_USAGE_STATS');
    final hasReadLogs = perms.contains('android.permission.READ_LOGS');
    final hasWriteStorage =
        perms.contains('android.permission.WRITE_EXTERNAL_STORAGE') ||
        perms.contains('android.permission.MANAGE_EXTERNAL_STORAGE');

    final dangerousCount =
        perms.where((p) => dangerousPermissions.contains(p)).length;

    // ── Source tier (dynamic weighted, replaces binary sideload flag) ─────
    final sourceTier = _classifyInstallSource(app.installSource, app.isSystemApp);
    final isSideloaded = (sourceTier == InstallSourceTier.unknownStore ||
            sourceTier == InstallSourceTier.adb) &&
        !app.isSystemApp;
    final isPlayStore = sourceTier == InstallSourceTier.playStore;

    // ── Category inference ────────────────────────────────────────────────
    final category = _inferCategory(
      app.packageName,
      app.appName,
      hasCam: hasCam,
      hasMic: hasMic,
      hasSms: hasSms,
      hasLoc: hasLoc,
      hasContacts: hasContacts,
    );

    // ── Behavior-based role classification ────────────────────────────────
    final role = _classifyRole(
      packageName: app.packageName,
      appName: app.appName,
      hasInstallPkgs: hasInstallPkgs,
      hasLaunchIntent: app.hasLaunchIntent,
      hasInternet: hasInternet,
      hasWriteStorage: hasWriteStorage,
      hasFgService: hasFgService,
      hasWakeLock: hasWakeLock,
      hasSms: hasSms,
      hasContacts: hasContacts,
      category: category,
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
      hasInstallPackagesPerm: hasInstallPkgs,
      hasDeviceAdminPerm: hasDevAdmin,
      hasUsageStatsPerm: hasUsageStats,
      hasReadLogsPerm: hasReadLogs,
      hasWriteStoragePerm: hasWriteStorage,
      isHiddenApp: !app.hasLaunchIntent,
      isUnknownSource: isSideloaded,
      appRole: role,
      installSourceTier: sourceTier,
      inferredCategory: category,
      requestedPermissions: app.requestedPermissions,
    );
  }

  // ─── Install source tier classification ──────────────────────────────────

  static InstallSourceTier _classifyInstallSource(
    String? installer,
    bool isSystemApp,
  ) {
    if (isSystemApp) return InstallSourceTier.none;

    // ADB / root install — no installer recorded
    if (installer == null || installer.isEmpty) return InstallSourceTier.adb;

    if (installer == 'com.android.vending' || installer == 'play_store') {
      return InstallSourceTier.playStore;
    }

    const trustedStores = {
      'com.sec.android.app.samsungapps', // Samsung Galaxy Store
      'com.xiaomi.mipicks',               // Xiaomi GetApps
      'com.huawei.appmarket',             // Huawei AppGallery
      'com.amazon.venezia',               // Amazon Appstore
      'com.oppo.market',                  // Oppo Market
      'com.heytap.market',                // HeytapMarket (OnePlus China)
    };

    if (trustedStores.contains(installer)) {
      return InstallSourceTier.trustedStore;
    }

    // Anything else is an unrecognized 3rd-party installer
    return InstallSourceTier.unknownStore;
  }

  // ─── Behavior-based role classification ──────────────────────────────────

  static AppRole _classifyRole({
    required String packageName,
    required String appName,
    required bool hasInstallPkgs,
    required bool hasLaunchIntent,
    required bool hasInternet,
    required bool hasWriteStorage,
    required bool hasFgService,
    required bool hasWakeLock,
    required bool hasSms,
    required bool hasContacts,
    required String category,
  }) {
    // Installer: can install other APKs — highest risk role
    if (hasInstallPkgs) return AppRole.installer;

    // Downloader: hidden + network + file write = dropper/downloader
    if (!hasLaunchIntent && hasInternet && hasWriteStorage) {
      return AppRole.downloader;
    }

    // Background service: hidden + persistent execution capability
    if (!hasLaunchIntent && (hasFgService || hasWakeLock)) {
      return AppRole.backgroundService;
    }

    // Communication: SMS/contacts or category match
    if (category == 'communication' || hasSms || hasContacts) {
      return AppRole.communication;
    }

    // Standard UI app
    if (hasLaunchIntent) return AppRole.uiApp;

    return AppRole.unknown;
  }

  // ─── Category inference (package + name + permissions) ───────────────────

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

    if (_matchesAny(pkgLower, nameLower, [
      'camera', 'photo', 'video', 'gallery', 'recorder', 'snap',
    ])) return 'media';

    if (_matchesAny(pkgLower, nameLower, [
      'calculator', 'calc', 'math', 'converter', 'unit',
    ])) return 'utility';

    if (_matchesAny(pkgLower, nameLower, [
      'messenger', 'chat', 'whatsapp', 'telegram', 'signal',
      'sms', 'message',
    ])) return 'communication';

    if (_matchesAny(pkgLower, nameLower, [
      'map', 'navigation', 'gps', 'uber', 'lyft', 'taxi', 'travel',
    ])) return 'navigation';

    if (_matchesAny(pkgLower, nameLower, [
      'bank', 'pay', 'wallet', 'finance', 'money', 'upi',
    ])) return 'finance';

    if (_matchesAny(pkgLower, nameLower, [
      'game', 'puzzle', 'arcade', 'racing',
    ])) return 'game';

    if (_matchesAny(pkgLower, nameLower, [
      'social', 'facebook', 'instagram', 'twitter', 'tiktok', 'reddit',
    ])) return 'social';

    if (_matchesAny(pkgLower, nameLower, [
      'flashlight', 'torch', 'clock', 'alarm', 'weather', 'note', 'todo',
    ])) return 'utility';

    if (_matchesAny(pkgLower, nameLower, [
      'browser', 'chrome', 'firefox', 'web',
    ])) return 'browser';

    if (_matchesAny(pkgLower, nameLower, [
      'music', 'audio', 'spotify', 'podcast', 'radio',
    ])) return 'media';

    if (_matchesAny(pkgLower, nameLower, [
      'file', 'manager', 'explorer', 'storage',
    ])) return 'filemanager';

    if (_matchesAny(pkgLower, nameLower, [
      'mail', 'email', 'gmail', 'outlook',
    ])) return 'communication';

    if (_matchesAny(pkgLower, nameLower, [
      'dialer', 'phone', 'call', 'contacts',
    ])) return 'communication';

    // Permission-based fallback (lower confidence)
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
        if (permission == 'android.permission.ACCESS_FINE_LOCATION') {
          return true;
        }
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
