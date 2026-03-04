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

  /// Analyzes a single app for dangerous permissions and combinations.
  /// Returns a Threat object if dangerous, or null if safe.
  Threat? analyzeAppPermissions(AppInfo app) {
    if (app.isSystemApp) return null; // Assume system apps are relatively safe for basic heuristic

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
