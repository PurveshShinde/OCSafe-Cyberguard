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
  /// Fetches permissions individually for each app.
  AppInfo mapToAppInfo(Application app) {
    final installSource = _safeInstallerPackage(app);
    final permissions = _safePermissions(app);

    return AppInfo(
      appName: app.appName,
      packageName: app.packageName,
      versionName: app.versionName ?? 'Unknown',
      isSystemApp: app.systemApp,
      installSource: installSource,
      requestedPermissions: permissions,
    );
  }

  /// Fetches an individual app WITH permissions (for real-time detection).
  Future<AppInfo?> fetchAppWithPermissions(String packageName) async {
    final app = await DeviceApps.getApp(packageName, true);
    if (app == null) return null;
    return mapToAppInfo(app);
  }

  /// Fetches all installed apps WITH permissions for deep scan.
  Future<List<AppInfo>> fetchAllAppsWithPermissions() async {
    final rawApps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: false,
    );
    final List<AppInfo> result = [];
    for (final raw in rawApps) {
      // Re-fetch each app with permissions: true to get requestedPermissions
      final appWithPerms = await DeviceApps.getApp(raw.packageName, true);
      if (appWithPerms != null) {
        result.add(mapToAppInfo(appWithPerms));
      } else {
        result.add(mapToAppInfo(raw));
      }
    }
    return result;
  }

  String? _safeInstallerPackage(Application app) {
    try {
      final d = app as dynamic;
      final val = d.installerPackageName as String?;
      return val;
    } catch (_) {
      return null;
    }
  }

  List<String> _safePermissions(Application app) {
    try {
      // ApplicationWithPermissions exposes requestedPermissions
      final d = app as dynamic;
      final perms = d.requestedPermissions;
      if (perms is List) {
        return perms.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
