/// Represents a detected security threat.
class Threat {
  final String appName;
  final String packageName;
  final String reason;
  final ThreatSeverity severity;

  const Threat({
    required this.appName,
    required this.packageName,
    required this.reason,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'reason': reason,
      'severity': severity.name,
    };
  }
}

enum ThreatSeverity { low, medium, high }
