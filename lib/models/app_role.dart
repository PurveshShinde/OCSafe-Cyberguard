/// Enum representing the inferred functional role of an installed application.
///
/// Role classification is **behavior-based** (permissions + launch intent),
/// not keyword-based, to reduce false positives.
enum AppRole {
  /// Can install other apps (`REQUEST_INSTALL_PACKAGES`).
  /// Highest risk role — treated as a separate threat category.
  installer,

  /// No launcher icon + Internet + file write capability.
  /// Classic profile of a payload dropper.
  downloader,

  /// No launcher icon but has ForegroundService or WakeLock.
  /// Runs silently in the background.
  backgroundService,

  /// Has a launcher icon and no dangerous capabilities.
  /// Standard user-facing app — lowest inherent risk.
  uiApp,

  /// Has SMS/Contacts permissions OR name/package matches communication terms.
  communication,

  /// Cannot be classified into any of the above.
  unknown,
}

/// Enum representing the confidence-tier of an app's install source.
///
/// Used as **CONTEXT** for multipliers and override rules — NOT as a
/// standalone scoring signal. Install source alone must NEVER cause
/// an app to be flagged.
enum InstallSourceTier {
  /// Installed from Google Play Store.
  playStore,

  /// Installed from a known OEM store (Samsung, Xiaomi, Huawei, Amazon).
  trustedStore,

  /// Installed from an unrecognized 3rd-party package installer.
  unknownStore,

  /// Installed via ADB / root with no installer package recorded.
  adb,

  /// System app — pre-installed with the OS.
  none,
}

/// Extension for human-readable labels used in RiskContext output.
extension AppRoleLabel on AppRole {
  String get label {
    switch (this) {
      case AppRole.installer:
        return 'App Installer';
      case AppRole.downloader:
        return 'Downloader / Dropper';
      case AppRole.backgroundService:
        return 'Background Service';
      case AppRole.uiApp:
        return 'UI Application';
      case AppRole.communication:
        return 'Communication App';
      case AppRole.unknown:
        return 'Unknown Role';
    }
  }
}

extension InstallSourceTierLabel on InstallSourceTier {
  String get label {
    switch (this) {
      case InstallSourceTier.playStore:
        return 'Google Play Store';
      case InstallSourceTier.trustedStore:
        return 'Trusted OEM Store';
      case InstallSourceTier.unknownStore:
        return 'Unknown 3rd-Party Store';
      case InstallSourceTier.adb:
        return 'ADB / Direct Install';
      case InstallSourceTier.none:
        return 'System App';
    }
  }
}
