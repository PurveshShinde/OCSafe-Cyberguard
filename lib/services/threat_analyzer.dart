import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/permission_scanner.dart';

class ThreatAnalyzer {
  final PermissionScanner _permissionScanner = PermissionScanner();

  static const List<String> suspiciousKeywords = [
    'hack', 'spy', 'tracker', 'keylog', 'stealth', 'hidden', 'monitor', 'record', 'inject'
  ];

  static const Map<String, String> popularAppsWhitelist = {
    'whatsapp': 'com.whatsapp',
    'facebook': 'com.facebook.katana',
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
    'telegram': 'com.telegram.messenger',
  };

  /// Main method for analyzing an app on the fly.
  /// Used by SecurityProvider to map and analyze in one go.
  Threat? analyzeApp(AppInfo app) {
    if (app.isSystemApp) return null; // Avoid flagging system apps for basic MVP

    List<String> reasons = [];
    int totalScore = 0;
    String recommendation = 'Review app usage or uninstall if unfamiliar.';
    String riskLevel = 'LOW';
    List<String> perms = app.requestedPermissions.where((p) => PermissionScanner.dangerousPermissionsList.contains(p)).toList();

    // 1. Check Permissions (uses PermissionScanner)
    final permissionThreat = _permissionScanner.analyzeAppPermissions(app);
    if (permissionThreat != null) {
      reasons.addAll(permissionThreat.reasons);
      totalScore += permissionThreat.threatScore;
      // Inherit recommendations if relevant
      recommendation = permissionThreat.recommendedAction;
      perms = permissionThreat.permissionsRequested;
    }

    // 2. Suspicious Package Name
    bool isSuspiciousPackage = suspiciousKeywords.any((keyword) => app.packageName.toLowerCase().contains(keyword));
    if (isSuspiciousPackage) {
      reasons.add('Suspicious keywords found in package name');
      totalScore += 30;
      recommendation = 'Highly suspicious app. Immediate uninstall recommended.';
    }

    // 3. Fake App Detection (Impersonation)
    bool isFakeApp = false;
    popularAppsWhitelist.forEach((name, realPackage) {
      if (app.appName.toLowerCase().contains(name) && app.packageName != realPackage) {
        isFakeApp = true;
      }
    });

    if (isFakeApp) {
      reasons.add('App impersonates popular application (e.g., WhatsApp, Instagram)');
      totalScore += 40;
      recommendation = 'Fake app detected. Immediate uninstall strongly recommended.';
    }

    // 4. Unknown Install Source (Bonus flag)
    if (app.installSource == null || (!app.installSource!.contains('android.vending') && !app.installSource!.contains('google'))) {
       // Only severely flag if combined with other issues, to avoid flagging F-Droid apps as high risk blindly.
       if (totalScore > 0) {
         reasons.add('Installed from unknown source (Side-loaded)');
         totalScore += 20;
       }
    }

    if (totalScore > 0) {
      // Cap max score to 100
      totalScore = totalScore > 100 ? 100 : totalScore;

      // Determine Risk Level
      if (totalScore >= 60) {
        riskLevel = 'HIGH';
      } else if (totalScore >= 30) {
        riskLevel = 'MEDIUM';
      } else {
        riskLevel = 'LOW';
      }

      return Threat(
        appName: app.appName,
        packageName: app.packageName,
        riskLevel: riskLevel,
        threatScore: totalScore,
        reasons: reasons,
        permissionsRequested: perms,
        recommendedAction: recommendation,
      );
    }

    return null;
  }

  /// Evaluates APK files found internally.
  List<Threat> evaluateApks(List<String> apkPaths) {
    return apkPaths.map((path) {
      return Threat(
        appName: path.split('/').last,
        packageName: 'Unknown Installer File',
        riskLevel: 'MEDIUM',
        threatScore: 25,
        reasons: ['APK installer detected (Could be side-loaded malware)'],
        permissionsRequested: [],
        recommendedAction: 'Delete the APK installer if you did not download it.',
      );
    }).toList();
  }
}
