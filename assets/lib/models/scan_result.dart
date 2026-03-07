import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/models/app_scan_result.dart';

/// Result of a security scan (ScanReport).
class ScanResult {
  final int? id;
  final DateTime scanDate;
  final int totalAppsScanned;
  final int threatCount;
  final int securityScore;
  final List<Threat> threats;
  final List<AppScanResult> appResults;
  /// 'full' = scanned installed apps + device storage; 'limited' = installed apps only.
  final String scanMode;

  const ScanResult({
    this.id,
    required this.scanDate,
    required this.totalAppsScanned,
    required this.threatCount,
    required this.securityScore,
    this.threats = const [],
    this.appResults = const [],
    this.scanMode = 'limited',
  });

  bool get isFullScan => scanMode == 'full';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scan_date': scanDate.toIso8601String(),
      'total_apps_scanned': totalAppsScanned,
      'threat_count': threatCount,
      'security_score': securityScore,
      'scan_mode': scanMode,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map, {
    List<Threat> threats = const [],
    List<AppScanResult> appResults = const [],
  }) {
    return ScanResult(
      id: map['id'] as int?,
      scanDate: DateTime.parse(map['scan_date'] as String),
      totalAppsScanned: map['total_apps_scanned'] as int,
      threatCount: map['threat_count'] as int,
      securityScore: map['security_score'] as int,
      threats: threats,
      appResults: appResults,
      scanMode: (map['scan_mode'] as String?) ?? 'limited',
    );
  }
}
