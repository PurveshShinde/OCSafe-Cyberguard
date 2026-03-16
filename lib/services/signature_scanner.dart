import 'package:ocsafe_cyberguard/services/threat_intel.dart';

class SignatureScanner {
  static final Map<String, String> _scanCache = {};

  /// Suspicious keywords often used by malware apps
  static const List<String> _suspiciousKeywords = [
    'cleaner',
    'booster',
    'security',
    'protect',
    'update',
    'vpnfree',
    'speedup',
  ];

  /// Scan a package name and classify its risk
  static String scanPackage(String packageName) {
    if (_scanCache.containsKey(packageName)) {
      return _scanCache[packageName]!;
    }

    String result = 'SAFE';

    // 1. Known malicious package
    if (ThreatIntel.isMaliciousPackage(packageName)) {
      result = 'MALICIOUS';
    }
    // 2. Suspicious namespace
    else if (!ThreatIntel.isTrustedPackage(packageName) &&
        ThreatIntel.hasSuspiciousNamespace(packageName)) {
      result = 'SUSPICIOUS';
    }
    // 3. Suspicious keyword detection
    else {
      final lower = packageName.toLowerCase();

      for (final keyword in _suspiciousKeywords) {
        if (lower.contains(keyword) &&
            !ThreatIntel.isTrustedPackage(packageName)) {
          result = 'SUSPICIOUS';
          break;
        }
      }
    }

    _scanCache[packageName] = result;
    return result;
  }

  /// Convenience boolean check for high-risk malware
  static bool isMaliciousPackage(String packageName) {
    return scanPackage(packageName) == 'MALICIOUS';
  }
}
