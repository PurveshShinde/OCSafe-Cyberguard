import 'dart:async';
import 'package:ocsafe_cyberguard/models/url_threat.dart';

class SafeBrowsingService {
  /// Known dangerous domains
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

  /// Suspicious keywords commonly used in phishing/scams
  static const List<String> _suspiciousKeywords = [
    'login',
    'verify',
    'update',
    'secure',
    'bank',
    'wallet',
    'crypto',
    'lottery',
    'bonus',
    'prize',
  ];

  /// Cache for previously scanned URLs
  final Map<String, UrlThreat?> _cache = {};

  /// Normalize domain
  String _normalizeDomain(String domain) {
    domain = domain.toLowerCase().trim();
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }
    return domain;
  }

  /// Checks URL for threats
  Future<UrlThreat?> checkUrl(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      final uri = Uri.parse(url);
      var domain = uri.host;

      if (domain.isEmpty) {
        _cache[url] = null;
        return null;
      }

      domain = _normalizeDomain(domain);

      // ---- Known phishing domain check ----
      for (final phishing in _phishingDomains) {
        if (domain == phishing || domain.endsWith('.$phishing')) {
          final threat = UrlThreat(
            url: url,
            domain: domain,
            riskLevel: 'HIGH',
            threatType: 'Phishing',
            description:
                'This domain is flagged as a known phishing or malware source. Avoid visiting this website.',
          );

          _cache[url] = threat;
          return threat;
        }
      }

      // ---- Suspicious keyword detection ----
      for (final keyword in _suspiciousKeywords) {
        if (domain.contains(keyword)) {
          final threat = UrlThreat(
            url: url,
            domain: domain,
            riskLevel: 'MEDIUM',
            threatType: _detectThreatType(keyword),
            description:
                'This domain contains patterns commonly used in phishing or scam websites.',
          );

          _cache[url] = threat;
          return threat;
        }
      }
    } catch (_) {
      // invalid URL
    }

    _cache[url] = null;
    return null;
  }

  /// Determine threat type from keyword
  String _detectThreatType(String keyword) {
    if (keyword.contains('bank') || keyword.contains('login')) {
      return 'Phishing';
    }

    if (keyword.contains('update')) {
      return 'Malware';
    }

    if (keyword.contains('crypto') ||
        keyword.contains('wallet') ||
        keyword.contains('bonus')) {
      return 'Crypto Scam';
    }

    if (keyword.contains('lottery') || keyword.contains('prize')) {
      return 'Lottery Scam';
    }

    return 'Suspicious';
  }

  /// Placeholder for future browser monitoring
  Stream<UrlThreat> monitorUrls() async* {
    yield* const Stream.empty();
  }
}
