class AppInfo {
  final String appName;
  final String packageName;
  final String versionName;
  final bool isSystemApp;
  final String? installSource;
  final String? apkFilePath;
  final List<String> requestedPermissions;
  final int versionCode;
  final bool hasLaunchIntent;

  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.isSystemApp,
    this.installSource,
    this.apkFilePath,
    this.requestedPermissions = const [],
    this.hasLaunchIntent = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'versionName': versionName,
      'versionCode': versionCode,
      'isSystemApp': isSystemApp,
      'installSource': installSource,
      'apkFilePath': apkFilePath,
      'requestedPermissions': requestedPermissions,
      'hasLaunchIntent': hasLaunchIntent,
    };
  }
}
