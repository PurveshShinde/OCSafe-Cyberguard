class ThreatIntel {
  /// Known malware package identifiers
  static const Set<String> maliciousPackageNames = {
    'com.fake.bank',
    'com.android.spy',
    'com.trojan.dropper',
  };

  /// Trusted system packages
  static const Set<String> trustedPackages = {
    'com.android.systemui',
    'com.google.android.gms',
    'com.android.vending',
    'com.ocsafe.ocsafe_cyberguard', // Trust ourselves
  };

  /// Trusted namespaces (system/OEM)
  static const List<String> trustedNamespaces = [
    'com.android.',
    'com.google.',
    'com.samsung.',
    'com.oneplus.',
    'com.oplus.',
    'com.coloros.',
    'com.heytap.',
    'com.miui.',
    'com.xiaomi.',
    'com.huawei.',
  ];

  /// Dangerous permissions commonly abused by malware
  static const Set<String> suspiciousPermissions = {
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'android.permission.BIND_DEVICE_ADMIN',
  };

  /// Suspicious namespace patterns
  static const Set<String> suspiciousNamespaces = {
    'update.service',
    'system.update',
    'android.security.patch',
    'hidden',
    'stealth',
    'monitor',
    'spy',
    'track',
  };

  /// Fake system naming patterns
  static const Set<String> fakeSystemPatterns = {
    'android.system',
    'system.service',
    'google.security',
    'android.update.service',
  };

  /// Hidden packages that are safe system components
  static const Set<String> safeHiddenPackages = {
    /// Core Google / Android
    'com.google.android.gms',
    'com.android.systemui',
    'com.android.vending',
    'com.google.android.gsf',
    'com.google.android.ext.services',
    'com.google.android.as',
    'com.google.android.networkstack.tethering',
    'com.android.keychain',
    'com.android.settings',

    /// OEM packages
    'com.oneplus.widget',
    'net.oneplus.widget',
    'com.oneplus.security',
    'com.oneplus.camera.service',
    'com.oplus.security',
    'com.oplus.battery',
    'com.oplus.pay',
    'com.samsung.android.lool',
    'com.samsung.android.securitylogagent',
    'com.xiaomi.discover',
    'com.coloros.safecenter',
    'com.heytap.mcs',

    /// Android services
    'com.android.providers.media.module',
    'com.android.providers.telephony',
    'com.android.bluetooth',
    'com.android.nfc',
    'com.android.certinstaller',

    /// System utilities
    'com.android.soundrecorder',
    'com.heytap.speechassist',
    'com.google.android.setupwizard',
    'com.coloros.lockassistant',
    'com.heytap.pictorial',
  };

  static String _normalize(String package) {
    return package.toLowerCase().trim();
  }

  static bool isMaliciousPackage(String packageName) {
    return maliciousPackageNames.contains(_normalize(packageName));
  }

  static bool isTrustedPackage(String packageName) {
    return trustedPackages.contains(_normalize(packageName));
  }

  static bool isTrustedNamespace(String packageName) {
    final pkg = _normalize(packageName);

    for (final ns in trustedNamespaces) {
      if (pkg.startsWith(ns)) return true;
    }

    return false;
  }

  static bool hasSuspiciousNamespace(String packageName) {
    final pkg = _normalize(packageName);

    for (final pattern in suspiciousNamespaces) {
      if (pkg.contains(pattern)) return true;
    }

    return false;
  }

  static bool hasFakeSystemPattern(String packageName) {
    final pkg = _normalize(packageName);

    for (final pattern in fakeSystemPatterns) {
      if (pkg.contains(pattern)) return true;
    }

    return false;
  }

  static bool isSafeHiddenPackage(String packageName) {
    return safeHiddenPackages.contains(_normalize(packageName));
  }
}
