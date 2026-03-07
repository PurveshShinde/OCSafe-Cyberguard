import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/threat_analyzer.dart';

class StealthAppDetector {
  /// Analyzes an app specifically for stealth / persistence behaviors.
  /// Returns a Threat object if stealth behavior is detected, otherwise null.
  Threat? detectStealthBehavior(AppInfo app) {
    if (app.isSystemApp) return null; // Skip system apps for generic stealth checks

    List<String> reasons = [];
    int stealthScore = 0;

    // 1. Hidden Launcher Icon (No Launch Intent)
    if (!app.hasLaunchIntent) {
      bool isTrustedNamespace = _isTrustedHiddenAppNamespace(app.packageName);
      bool isAllowed = ThreatAnalyzer.safeHiddenPackages.contains(app.packageName);

      if (!isTrustedNamespace && !isAllowed) {
        reasons.add('Hidden background app detected (no launcher icon)');
        stealthScore += 30;
      }
    }

    // 2. Accessibility Abuse Potential
    if (app.requestedPermissions.contains('android.permission.BIND_ACCESSIBILITY_SERVICE')) {
      reasons.add('App requests powerful Accessibility Service (often abused for screen reading/control)');
      stealthScore += 40;
    }

    // 3. Overlay Attack Capability
    if (app.requestedPermissions.contains('android.permission.SYSTEM_ALERT_WINDOW')) {
      reasons.add('App requests permission to draw over other apps (Overlay attack risk)');
      stealthScore += 20;
    }

    // 4. Boot Persistence
    if (app.requestedPermissions.contains('android.permission.RECEIVE_BOOT_COMPLETED')) {
      reasons.add('App sets itself to start automatically on device boot');
      stealthScore += 10;
    }

    // 5. Background Persistence (Services)
    if (app.requestedPermissions.contains('android.permission.FOREGROUND_SERVICE') || 
        app.requestedPermissions.contains('android.permission.FOREGROUND_SERVICE_DATA_SYNC')) {
       // Only add to reasons if there are other suspicious factors, as many legit apps use foreground services
       if (stealthScore >= 30) {
          reasons.add('App uses persistent background services');
          stealthScore += 10;
       }
    }

    // Only return a threat if the score represents a genuine risk.
    // Combinations (e.g., Hidden + Boot + Overlay) will trigger a high score.
    if (stealthScore >= 30) {
      String riskLevel = stealthScore >= 60 ? 'HIGH' : 'MEDIUM';
      String recommendation = stealthScore >= 60 
          ? 'Highly suspicious stealth app. Immediate uninstall recommended.'
          : 'App exhibits stealthy behavior. Verify you intentionally installed it.';

      return Threat(
        appName: app.appName.isNotEmpty ? app.appName : app.packageName,
        packageName: app.packageName,
        riskLevel: riskLevel,
        threatScore: stealthScore > 100 ? 100 : stealthScore,
        reasons: reasons,
        permissionsRequested: app.requestedPermissions,
        recommendedAction: recommendation,
      );
    }

    return null;
  }

  bool _isTrustedHiddenAppNamespace(String packageName) {
    return packageName.startsWith('com.android.') ||
           packageName.startsWith('com.google.') ||
           packageName.startsWith('com.samsung.') ||
           packageName.startsWith('com.oneplus.') ||
           packageName.startsWith('com.oplus.') ||
           packageName.startsWith('com.coloros.') ||
           packageName.startsWith('com.xiaomi.') ||
           packageName.startsWith('com.huawei.') ||
           packageName.startsWith('com.heytap.');
  }
}
