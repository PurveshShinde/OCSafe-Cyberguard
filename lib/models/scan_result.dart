import 'package:ocsafe_cyberguard/models/threat.dart';

/// Result of a security scan.
class ScanResult {
  final int? id;
  final DateTime scanDate;
  final int totalAppsScanned;
  final int threatCount;
  final int securityScore;
  final List<Threat> threats;

  const ScanResult({
    this.id,
    required this.scanDate,
    required this.totalAppsScanned,
    required this.threatCount,
    required this.securityScore,
    this.threats = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'scan_date': scanDate.toIso8601String(),
      'total_apps_scanned': totalAppsScanned,
      'threat_count': threatCount,
      'security_score': securityScore,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] as int?,
      scanDate: DateTime.parse(map['scan_date'] as String),
      totalAppsScanned: map['total_apps_scanned'] as int,
      threatCount: map['threat_count'] as int,
      securityScore: map['security_score'] as int,
    );
  }
}
