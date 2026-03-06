/// Represents a detected security threat.
class Threat {
  final int? id;
  final int? scanId;
  final String appName;
  final String packageName;
  final String riskLevel; // 'HIGH', 'MEDIUM', 'LOW'
  final int threatScore;
  final List<String> reasons;
  final List<String> permissionsRequested;
  final String recommendedAction;
  /// 'app' = installed application, 'file' = APK/archive found on device storage
  final String threatType;

  const Threat({
    this.id,
    this.scanId,
    required this.appName,
    required this.packageName,
    required this.riskLevel,
    required this.threatScore,
    required this.reasons,
    required this.permissionsRequested,
    required this.recommendedAction,
    this.threatType = 'app',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scan_id': scanId,
      'app_name': appName,
      'package_name': packageName,
      'risk_level': riskLevel,
      'threat_score': threatScore,
      'reasons': reasons.join('|'), // Delimited string for simple SQLite storage
      'permissions': permissionsRequested.join('|'),
      'recommendation': recommendedAction,
      'threat_type': threatType,
    };
  }

  factory Threat.fromMap(Map<String, dynamic> map) {
    return Threat(
      id: map['id'] as int?,
      scanId: map['scan_id'] as int?,
      appName: map['app_name'] as String,
      packageName: map['package_name'] as String,
      riskLevel: map['risk_level'] as String,
      threatScore: map['threat_score'] as int,
      reasons: (map['reasons'] as String).isEmpty ? [] : (map['reasons'] as String).split('|'),
      permissionsRequested: (map['permissions'] as String).isEmpty ? [] : (map['permissions'] as String).split('|'),
      recommendedAction: map['recommendation'] as String,
      threatType: (map['threat_type'] as String?) ?? 'app',
    );
  }
}

enum ThreatSeverity { low, medium, high }
