import 'package:device_apps/device_apps.dart';
import 'package:ocsafe_cyberguard/models/app_info.dart';

class AppScanner {
  /// Fetches the list of installed applications via device_apps.
  Future<List<Application>> fetchRawInstalledApps() async {
    return await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: false,
    );
  }

  /// Maps a native Application to our AppInfo domain model.
  AppInfo mapToAppInfo(Application app) {
    // In device_apps 2.2.0 the Application object exposes installerPackageName
    // but permissions are not available without fetching individual app details.
    // We rely on app-level metadata only here.
    final installSource = _safeInstallerPackage(app);

    return AppInfo(
      appName: app.appName,
      packageName: app.packageName,
      versionName: app.versionName ?? 'Unknown',
      isSystemApp: app.systemApp,
      installSource: installSource,
      requestedPermissions: const [], // Permissions not available via batch fetch in device_apps 2.2.0
    );
  }

  String? _safeInstallerPackage(Application app) {
    try {
      // installerPackageName is available on Application in device_apps 2.2.0
      final d = app as dynamic;
      final val = d.installerPackageName as String?;
      return val;
    } catch (_) {
      return null;
    }
  }
}
