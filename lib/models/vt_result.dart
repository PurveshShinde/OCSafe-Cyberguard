/// Result of a VirusTotal file/hash lookup.
class VTResult {
  final int malicious;
  final int suspicious;
  final int undetected;
  final int harmless;
  final DateTime checkedAt;
  final String hash;
  final String packageName;
  final String? versionCode;

  const VTResult({
    required this.malicious,
    required this.suspicious,
    required this.undetected,
    required this.harmless,
    required this.checkedAt,
    required this.hash,
    required this.packageName,
    this.versionCode,
  });

  /// Total number of engines that scanned this file.
  int get totalEngines => malicious + suspicious + undetected + harmless;

  /// Ratio of malicious detections to total engines (0.0 – 1.0).
  double get maliciousRatio =>
      totalEngines > 0 ? malicious / totalEngines : 0.0;

  /// Ratio of suspicious detections to total engines (0.0 – 1.0).
  double get suspiciousRatio =>
      totalEngines > 0 ? suspicious / totalEngines : 0.0;

  /// Whether this result is considered expired.
  /// Default TTL: 24h — balances freshness vs API quota.
  bool isExpired({Duration ttl = const Duration(hours: 24)}) {
    return DateTime.now().difference(checkedAt) > ttl;
  }

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'package_name': packageName,
      'version_code': versionCode,
      'malicious': malicious,
      'suspicious': suspicious,
      'undetected': undetected,
      'harmless': harmless,
      'checked_at': checkedAt.toIso8601String(),
    };
  }

  factory VTResult.fromMap(Map<String, dynamic> map) {
    return VTResult(
      hash: map['hash'] as String,
      packageName: map['package_name'] as String,
      versionCode: map['version_code'] as String?,
      malicious: map['malicious'] as int? ?? 0,
      suspicious: map['suspicious'] as int? ?? 0,
      undetected: map['undetected'] as int? ?? 0,
      harmless: map['harmless'] as int? ?? 0,
      checkedAt: DateTime.parse(map['checked_at'] as String),
    );
  }
}
