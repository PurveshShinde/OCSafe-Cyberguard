import 'package:ocsafe_cyberguard/services/threat_intel.dart';

class SignatureScanner {
  static bool isMaliciousPackage(String packageName) {
    // 1. Direct match with malicious list
    if (ThreatIntel.isMaliciousPackage(packageName)) {
      return true;
    }

    // 2. Not trusted AND uses a suspicious namespace
    if (!ThreatIntel.isTrustedPackage(packageName) &&
        ThreatIntel.hasSuspiciousNamespace(packageName)) {
      return true;
    }

    return false;
  }
}
