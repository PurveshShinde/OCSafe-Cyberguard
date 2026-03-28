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

  // ── VirusTotal fields ──
  final int? vtMalicious;
  final int? vtSuspicious;
  final bool vtChecked;

  // ── Confidence score (0–100): how many independent signals agree ──
  final int confidence;

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
    this.vtMalicious,
    this.vtSuspicious,
    this.vtChecked = false,
    this.confidence = 0,
  });

  /// Creates a copy with optional field overrides.
  Threat copyWith({
    int? threatScore,
    String? riskLevel,
    List<String>? reasons,
    String? recommendedAction,
    int? vtMalicious,
    int? vtSuspicious,
    bool? vtChecked,
    int? confidence,
  }) {
    return Threat(
      id: id,
      scanId: scanId,
      appName: appName,
      packageName: packageName,
      riskLevel: riskLevel ?? this.riskLevel,
      threatScore: threatScore ?? this.threatScore,
      reasons: reasons ?? this.reasons,
      permissionsRequested: permissionsRequested,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      threatType: threatType,
      vtMalicious: vtMalicious ?? this.vtMalicious,
      vtSuspicious: vtSuspicious ?? this.vtSuspicious,
      vtChecked: vtChecked ?? this.vtChecked,
      confidence: confidence ?? this.confidence,
    );
  }

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
      'vt_malicious': vtMalicious ?? 0,
      'vt_suspicious': vtSuspicious ?? 0,
      'vt_checked': vtChecked ? 1 : 0,
      'confidence': confidence,
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
      vtMalicious: map['vt_malicious'] as int?,
      vtSuspicious: map['vt_suspicious'] as int?,
      vtChecked: (map['vt_checked'] as int?) == 1,
      confidence: (map['confidence'] as int?) ?? 0,
    );
  }
}

enum ThreatSeverity { low, medium, high }
