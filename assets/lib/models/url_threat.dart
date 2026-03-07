class UrlThreat {
  final String url;
  final String domain;
  final String riskLevel;
  final String threatType; // e.g., 'Phishing', 'Malware', 'Scam'
  final String description;
  final DateTime detectedAt;

  UrlThreat({
    required this.url,
    required this.domain,
    required this.riskLevel,
    required this.threatType,
    required this.description,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'domain': domain,
      'riskLevel': riskLevel,
      'threatType': threatType,
      'description': description,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory UrlThreat.fromMap(Map<String, dynamic> map) {
    return UrlThreat(
      url: map['url'],
      domain: map['domain'],
      riskLevel: map['riskLevel'],
      threatType: map['threatType'],
      description: map['description'],
      detectedAt: DateTime.parse(map['detectedAt']),
    );
  }
}
