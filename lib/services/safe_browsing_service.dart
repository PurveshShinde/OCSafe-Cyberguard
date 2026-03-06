import 'dart:async';
import 'package:ocsafe_cyberguard/models/url_threat.dart';

class SafeBrowsingService {
  // User provided phishing domain list
  static const Set<String> _phishingDomains = {
    'malware.test',
    'phishing.test',
    'fakebank-login.com',
    'crypto-giveaway.net',
    'phishing-test-site.com',
    'malware-test.net',
    'get-free-bitcoins.now',
    'bank-login-verify.top',
    'secure-update-android.xyz',
    'login.trusted-bank.co',
    'win-lottery-prize.info',
  };

  /// Checks a URL against known threats.
  Future<UrlThreat?> checkUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();
      
      if (_phishingDomains.contains(domain)) {
        return UrlThreat(
          url: url,
          domain: domain,
          riskLevel: 'HIGH',
          threatType: _getThreatType(domain),
          description: 'Known phishing domain. This website is flagged as dangerous. Do not open this website.',
        );
      }
    } catch (e) {
      // Invalid URL
    }

    return null;
  }

  String _getThreatType(String domain) {
    if (domain.contains('login') || domain.contains('bank')) return 'Phishing';
    if (domain.contains('malware') || domain.contains('update')) return 'Malware';
    if (domain.contains('win') || domain.contains('lottery')) return 'Scam';
    return 'Suspicious';
  }

  /// Conceptual method for monitoring clipboard or using AccessibilityService.
  /// In a real implementation, this would be triggered by an AccessibilityService
  /// that captures URL changes in the browser's address bar.
  Stream<UrlThreat> monitorUrls() async* {
    // This is a placeholder for demonstration.
    // Real implementation would use platform channels to communicate with an
    // Android AccessibilityService.
    yield* const Stream.empty();
  }
}
