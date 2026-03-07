import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';

class StealthAppDetector {
  static bool isStealthApp(AppInfo app) {
    if (app.hasLaunchIntent) return false;

    // A hidden app is only flagged if it's not a known safe package
    if (ThreatIntel.isSafeHiddenPackage(app.packageName)) return false;

    // Check for suspicious indicators
    final hasSuspiciousNamespace = ThreatIntel.hasSuspiciousNamespace(app.packageName);
    final hasDangerousPermissions = app.requestedPermissions.any((p) => 
      p.contains('SYSTEM_ALERT_WINDOW') || 
      p.contains('BIND_ACCESSIBILITY_SERVICE') ||
      p.contains('RECORD_AUDIO') ||
      p.contains('READ_SMS') ||
      p.contains('READ_CONTACTS') ||
      p.contains('ACCESS_FINE_LOCATION')
    );
    
    // Sensitivity: Flag if it has NO launch intent AND (suspicious name OR dangerous permissions)
    if (hasSuspiciousNamespace || hasDangerousPermissions) {
      return true;
    }

    return false;
  }
}
