import 'package:device_apps/device_apps.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

/// Service for scanning installed apps and detecting threats.
class ScanService {
  /// Keywords that indicate a potentially suspicious application.
  static const List<String> _suspiciousKeywords = [
    'hack', 'spy', 'tracker', 'monitor', 'keylog',
    'stealth', 'hidden', 'sniff', 'intercept', 'exploit',
    'phish', 'malware', 'trojan', 'spoof', 'crack',
  ];

  /// Gets all installed applications on the device.
  Future<List<Application>> scanInstalledApps() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: false,
        includeAppIcons: false,
        onlyAppsWithLaunchIntent: true,
      );
      return apps;
    } catch (e) {
      return [];
    }
  }

  /// Checks installed apps against suspicious keywords.
  /// Returns a list of threats found.
  List<Threat> detectSuspiciousApps(List<Application> apps) {
    final threats = <Threat>[];

    for (final app in apps) {
      final packageLower = app.packageName.toLowerCase();
      final nameLower = app.appName.toLowerCase();

      for (final keyword in _suspiciousKeywords) {
        if (packageLower.contains(keyword) || nameLower.contains(keyword)) {
          threats.add(Threat(
            appName: app.appName,
            packageName: app.packageName,
            reason: 'App name/package contains suspicious keyword: "$keyword"',
            severity: _getSeverity(keyword),
          ));
          break; // Only flag each app once
        }
      }
    }

    return threats;
  }

  /// Calculates a security score based on threats and protection status.
  /// Returns a score from 0 to 100.
  int calculateSecurityScore({
    required int threatCount,
    required int dangerousPermissions,
    required bool realtimeProtectionEnabled,
  }) {
    int score = 100;
    score -= (threatCount * 10).clamp(0, 40);
    score -= (dangerousPermissions * 5).clamp(0, 25);
    if (!realtimeProtectionEnabled) score -= 20;
    return score.clamp(0, 100);
  }

  ThreatSeverity _getSeverity(String keyword) {
    const highSeverity = ['hack', 'exploit', 'malware', 'trojan', 'keylog'];
    const mediumSeverity = ['spy', 'sniff', 'intercept', 'phish', 'spoof'];

    if (highSeverity.contains(keyword)) return ThreatSeverity.high;
    if (mediumSeverity.contains(keyword)) return ThreatSeverity.medium;
    return ThreatSeverity.low;
  }
}
