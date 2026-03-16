import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

class PermissionScanner {
  static const List<String> dangerousPermissionsList = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_SMS',
    'android.permission.SEND_SMS',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.INTERNET',
    'android.permission.BIND_ACCESSIBILITY_SERVICE',
  ];

  /// Trusted OEM / stock system app package names
  static const List<String> _trustedSystemPackages = [
    // OnePlus / OPlus
    'com.oneplus.recorder',
    'com.oplus.speechassistant',
    'com.oneplus.camera',
    'com.oplus.camera',
    'com.oneplus.dialer',
    'com.oplus.dialer',
    'com.oneplus.gallery',
    'com.oplus.gallery3d',
    'com.oneplus.filemanager',
    'com.oplus.filemanager',
    'com.coloros.recorder',
    'com.coloros.soundrecorder',
    'com.coloros.camera',
    'com.coloros.phonemanager',
    'com.coloros.gallery3d',
    'com.heytap.soundrecorder',
    'com.heytap.cloud',
    'com.heytap.browser',

    // Samsung
    'com.samsung.android.app.recorder',
    'com.sec.android.app.camera',
    'com.samsung.android.dialer',
    'com.samsung.android.gallery3d',
    'com.samsung.android.app.telephonyui',

    // Xiaomi
    'com.miui.recorder',
    'com.android.camera',
    'com.miui.gallery',
    'com.miui.phone',

    // AOSP / Google
    'com.android.soundrecorder',
    'com.android.dialer',
    'com.android.contacts',
    'com.android.camera2',
    'com.google.android.dialer',
    'com.google.android.contacts',
    'com.google.android.apps.photos',
    'com.google.android.gm',
    'com.google.android.apps.maps',
  ];

  /// Trusted prefixes for OEM / system apps
  static const List<String> _trustedPrefixes = [
    'com.android.',
    'com.google.android.',
    'com.oneplus.',
    'net.oneplus.',
    'com.oplus.',
    'com.coloros.',
    'com.heytap.',
    'com.samsung.android.',
    'com.sec.android.',
    'com.miui.',
    'com.huawei.',
    'com.hihonor.',
  ];

  /// Returns true if app is trusted system component
  bool _isTrustedApp(AppInfo app) {
    if (app.isSystemApp) return true;

    final pkg = app.packageName.toLowerCase();

    if (_trustedSystemPackages.any((p) => p.toLowerCase() == pkg)) {
      return true;
    }

    if (_trustedPrefixes.any((prefix) => pkg.startsWith(prefix))) {
      return true;
    }

    return false;
  }

  /// Main permission analysis
  Threat? analyzeAppPermissions(AppInfo app) {
    if (_isTrustedApp(app)) return null;

    final perms = app.requestedPermissions;
    if (perms.isEmpty) return null;

    final hasCamera = perms.contains('android.permission.CAMERA');
    final hasMic = perms.contains('android.permission.RECORD_AUDIO');
    final hasLocation =
        perms.contains('android.permission.ACCESS_FINE_LOCATION') ||
        perms.contains('android.permission.ACCESS_COARSE_LOCATION');

    final hasInternet = perms.contains('android.permission.INTERNET');
    final hasOverlay = perms.contains('android.permission.SYSTEM_ALERT_WINDOW');
    final hasSms =
        perms.contains('android.permission.READ_SMS') ||
        perms.contains('android.permission.SEND_SMS');

    final hasContacts = perms.contains('android.permission.READ_CONTACTS');

    final hasAccessibility =
        perms.contains('android.permission.BIND_ACCESSIBILITY_SERVICE');

    List<String> reasons = [];
    int threatScore = 0;

    String recommendation =
        'Review app permissions if you do not recognize this app.';

    /// ---- Surveillance detection ----
    if (hasCamera && hasMic && hasInternet) {
      reasons.add(
          'Requests Camera + Microphone + Internet (Possible surveillance behavior)');
      threatScore += 25;
      recommendation =
          'If the app does not require camera and microphone, consider uninstalling it.';
    }

    /// ---- Accessibility abuse (banking malware pattern) ----
    if (hasAccessibility && hasInternet) {
      reasons.add(
          'Uses Accessibility Service with Internet access (Common malware behavior)');
      threatScore += 35;
      recommendation =
          'Disable accessibility permission for this app unless absolutely required.';
    }

    /// ---- Overlay phishing detection ----
    if (hasOverlay && hasInternet) {
      reasons.add(
          'Requests Screen Overlay + Internet (Possible phishing or ad fraud)');
      threatScore += 25;
      recommendation =
          'Revoke "Display over other apps" permission if not required.';
    }

    /// ---- SMS fraud / trojan ----
    if (hasSms && hasInternet) {
      reasons.add(
          'Requests SMS access with Internet (Potential SMS fraud risk)');
      threatScore += 25;
    }

    /// ---- Data exfiltration ----
    if (hasContacts && hasInternet) {
      reasons.add(
          'Requests Contacts access with Internet (Potential data exfiltration)');
      threatScore += 20;
    }

    /// ---- Tracking detection ----
    if (hasLocation && hasInternet) {
      reasons.add(
          'Requests Location + Internet (Possible location tracking)');
      threatScore += 15;
    }

    /// ---- Risk classification ----
    String riskLevel = 'LOW';

    if (threatScore >= 50) {
      riskLevel = 'HIGH';
    } else if (threatScore >= 25) {
      riskLevel = 'MEDIUM';
    }

    if (threatScore == 0) return null;

    return Threat(
      appName: app.appName,
      packageName: app.packageName,
      riskLevel: riskLevel,
      threatScore: threatScore,
      reasons: reasons,
      permissionsRequested:
          perms.where((p) => dangerousPermissionsList.contains(p)).toList(),
      recommendedAction: recommendation,
    );
  }
}