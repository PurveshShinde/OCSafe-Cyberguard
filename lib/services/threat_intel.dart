class ThreatIntel {
  static const Set<String> maliciousPackageNames = {
    'com.fake.bank',
    'com.android.spy',
    'com.trojan.dropper',
    // ... add more as needed
  };

  static const Set<String> trustedPackages = {
    'com.android.systemui',
    'com.google.android.gms',
    'com.android.vending',
    // ... add more as needed
  };

  static const Set<String> suspiciousPermissions = {
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'android.permission.BIND_DEVICE_ADMIN',
    // ... add more as needed
  };

  static const Set<String> suspiciousNamespaces = {
    'update.service',
    'system.update',
    'android.security.patch',
    'hidden',
    'stealth',
    'monitor',
    'spy',
    'track',
    // ... add more as needed
  };

  static const List<String> safeHiddenPackages = [
    // Core Google/Android
    'com.google.android.gms',
    'com.android.systemui',
    'com.android.vending',
    'com.google.android.gsf',
    'com.google.android.ext.services',
    'com.google.android.as', // Android System Intelligence
    'com.google.android.networkstack.tethering',
    'com.android.keychain',
    'com.android.settings',

    // Common OEMs (OnePlus, Samsung, Xiaomi, etc.)
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

    // Other System level components
    'com.android.providers.media.module',
    'com.android.providers.telephony',
    'com.android.bluetooth',
    'com.android.nfc',
    'com.android.certinstaller',
    
    // Media / Companion Apps mentioned by user
    'com.android.soundrecorder',
    'com.heytap.speechassist',
    'com.google.android.setupwizard',
    'com.coloros.lockassistant', // Lock screen magazine
    'com.heytap.pictorial', // Lock screen magazine alternative
  ];

  static bool isMaliciousPackage(String packageName) {
    return maliciousPackageNames.contains(packageName);
  }

  static bool isTrustedPackage(String packageName) {
    return trustedPackages.contains(packageName);
  }

  static bool hasSuspiciousNamespace(String packageName) {
    for (final pattern in suspiciousNamespaces) {
      if (packageName.toLowerCase().contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  static bool isSafeHiddenPackage(String packageName) {
    return safeHiddenPackages.contains(packageName);
  }
}
