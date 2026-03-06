import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

class PermissionScanner {
  static const List<String> dangerousPermissionsList = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO', // Microphone
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_SMS',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.INTERNET',
  ];

  /// Trusted OEM / stock system app package names that should never be flagged
  /// for permission-combination rules even if they request Camera+Mic+Internet etc.
  static const List<String> _trustedSystemPackages = [
    // OnePlus / OPlus (Nord 4 and similar devices)
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
    // Xiaomi / MIUI
    'com.miui.recorder',
    'com.android.camera',
    'com.miui.gallery',
    'com.miui.phone',
    // AOSP / Android stock
    'com.android.soundrecorder',
    'com.android.dialer',
    'com.android.contacts',
    'com.android.camera2',
    'com.android.camera',
    'com.google.android.dialer',
    'com.google.android.contacts',
    'com.google.android.apps.photos',
    'com.google.android.gm', // Gmail
    'com.google.android.apps.maps',
  ];

  /// Trusted package prefixes — any app starting with these is considered a
  /// stock OEM component and is excluded from permission-combination heuristics.
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

  /// Returns true if the app is a trusted OEM/system component that should be
  /// exempted from permission-combination threat rules.
  bool _isTrustedApp(AppInfo app) {
    if (app.isSystemApp) return true;
    final pkg = app.packageName.toLowerCase();
    if (_trustedSystemPackages.any((p) => p.toLowerCase() == pkg)) return true;
    if (_trustedPrefixes.any((prefix) => pkg.startsWith(prefix))) return true;
    return false;
  }

  /// Analyzes a single app for dangerous permissions and combinations.
  /// Returns a Threat object if dangerous, or null if safe.
  Threat? analyzeAppPermissions(AppInfo app) {
    if (_isTrustedApp(app)) return null; // Never flag trusted OEM/system apps


    final perms = app.requestedPermissions;
    if (perms.isEmpty) return null;

    bool hasCamera = perms.contains('android.permission.CAMERA');
    bool hasMic = perms.contains('android.permission.RECORD_AUDIO');
    bool hasLocation = perms.contains('android.permission.ACCESS_FINE_LOCATION') || 
                       perms.contains('android.permission.ACCESS_COARSE_LOCATION');
    bool hasInternet = perms.contains('android.permission.INTERNET');
    bool hasOverlay = perms.contains('android.permission.SYSTEM_ALERT_WINDOW');
    bool hasSms = perms.contains('android.permission.READ_SMS');
    bool hasContacts = perms.contains('android.permission.READ_CONTACTS');

    List<String> reasons = [];
    int threatScore = 0;
    String riskLevel = 'LOW';
    String recommendation = 'Review app permissions if you do not recognize this app.';

    // Combination: Camera + Mic + Internet
    if (hasCamera && hasMic && hasInternet) {
      reasons.add('Requests Camera, Microphone, and Internet (High Risk of surveillance)');
      threatScore += 25;
      riskLevel = 'HIGH';
      recommendation = 'Consider uninstalling if you do not actively use its camera/mic features.';
    }

    // Combination: Overlay + Internet
    if (hasOverlay && hasInternet) {
      reasons.add('Requests Screen Overlay and Internet (Risk of ad-fraud or phishing)');
      threatScore += 25;
      riskLevel = 'HIGH';
      recommendation = 'Revoke "Display over other apps" permission in settings.';
    }

    // Combination: Location + Internet
    if (hasLocation && hasInternet && riskLevel != 'HIGH') {
      reasons.add('Requests Location and Internet (Medium Risk of tracking)');
      threatScore += 15;
      riskLevel = 'MEDIUM';
    }

    // Combination: SMS + Contacts + Internet
    if (hasSms && hasContacts && hasInternet) {
      reasons.add('Requests SMS, Contacts, and Internet (High Risk of data exfiltration)');
      threatScore += 25;
      riskLevel = 'HIGH';
    }

    if (threatScore > 0) {
      return Threat(
        appName: app.appName,
        packageName: app.packageName,
        riskLevel: riskLevel,
        threatScore: threatScore,
        reasons: reasons,
        permissionsRequested: perms.where((p) => dangerousPermissionsList.contains(p)).toList(),
        recommendedAction: recommendation,
      );
    }

    return null;
  }
}
