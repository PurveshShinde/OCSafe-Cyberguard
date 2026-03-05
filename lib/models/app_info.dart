class AppInfo {
  final String appName;
  final String packageName;
  final String versionName;
  final bool isSystemApp;
  final String? installSource;
  final List<String> requestedPermissions;
  final bool hasLaunchIntent;

  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.isSystemApp,
    this.installSource,
    this.requestedPermissions = const [],
    this.hasLaunchIntent = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'versionName': versionName,
      'isSystemApp': isSystemApp,
      'installSource': installSource,
      'requestedPermissions': requestedPermissions,
      'hasLaunchIntent': hasLaunchIntent,
    };
  }
}
