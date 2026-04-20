/// Structured explanation of WHY an app is risky.
///
/// Separates *what was detected* from *how severe* it is, allowing
/// the UI to present human-readable context instead of raw scores.
class RiskContext {
  /// The inferred functional role of the app (e.g. 'App Installer').
  final String appRole;

  /// Human-readable install source (e.g. 'ADB / Direct Install').
  final String installSourceLabel;

  /// Active high-risk capabilities detected on this app.
  /// Examples: ['CAN_INSTALL_APPS', 'DEVICE_ADMIN', 'ACCESSIBILITY_ABUSE']
  final List<String> capabilityFlags;

  const RiskContext({
    required this.appRole,
    required this.installSourceLabel,
    this.capabilityFlags = const [],
  });

  Map<String, dynamic> toMap() => {
        'appRole': appRole,
        'installSourceLabel': installSourceLabel,
        'capabilityFlags': capabilityFlags.join('|'),
      };

  factory RiskContext.fromMap(Map<String, dynamic> map) => RiskContext(
        appRole: map['appRole'] as String? ?? 'Unknown Role',
        installSourceLabel:
            map['installSourceLabel'] as String? ?? 'Unknown Source',
        capabilityFlags:
            (map['capabilityFlags'] as String? ?? '').isEmpty
                ? []
                : (map['capabilityFlags'] as String).split('|'),
      );
}

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

  // ── Confidence score (0–100): certainty of the detection, separate from severity ──
  final int confidence;

  // ── Structured risk explanation ──
  final RiskContext? riskContext;

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
    this.riskContext,
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
    RiskContext? riskContext,
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
      riskContext: riskContext ?? this.riskContext,
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
