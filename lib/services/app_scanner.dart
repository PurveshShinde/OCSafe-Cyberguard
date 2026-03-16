import 'package:device_apps/device_apps.dart';
import 'package:flutter/services.dart';
import 'package:ocsafe_cyberguard/models/app_info.dart';

@pragma('vm:entry-point')
Future<List<AppInfo>> fetchAllAppsBackground(RootIsolateToken token) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final scanner = AppScanner();
  return await scanner.fetchAllAppsWithPermissions();
}

class AppScanner {
  /// Fetch raw installed apps
  Future<List<Application>> fetchRawInstalledApps() async {
    return await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: false,
      onlyAppsWithLaunchIntent: false,
    );
  }

  /// Maps Application → AppInfo
  AppInfo mapToAppInfo(Application app, {required bool hasLaunchIntent}) {
    final installSource = _safeInstallerPackage(app);
    final permissions = _safePermissions(app);

    return AppInfo(
      appName: app.appName,
      packageName: app.packageName,
      versionName: app.versionName ?? 'Unknown',
      isSystemApp: app.systemApp,
      installSource: installSource,
      requestedPermissions: permissions,
      hasLaunchIntent: hasLaunchIntent,
    );
  }

  /// Fetch one app with permissions
  Future<AppInfo?> fetchAppWithPermissions(String packageName) async {
    final app = await DeviceApps.getApp(packageName, true);

    if (app == null) return null;

    final hasLaunchIntent = app is ApplicationWithIcon;

    return mapToAppInfo(app, hasLaunchIntent: hasLaunchIntent);
  }

  /// Fetch all apps with permissions
  Future<List<AppInfo>> fetchAllAppsWithPermissions() async {
    final rawApps = await fetchRawInstalledApps();

    final futures = rawApps.map((raw) async {
      try {
        final appWithPerms = await DeviceApps.getApp(raw.packageName, true);

        if (appWithPerms != null) {
          final hasLaunchIntent = appWithPerms is ApplicationWithIcon;

          return mapToAppInfo(appWithPerms, hasLaunchIntent: hasLaunchIntent);
        }

        final hasLaunchIntent = raw is ApplicationWithIcon;

        return mapToAppInfo(raw, hasLaunchIntent: hasLaunchIntent);
      } catch (_) {
        final hasLaunchIntent = raw is ApplicationWithIcon;

        return mapToAppInfo(raw, hasLaunchIntent: hasLaunchIntent);
      }
    });

    final apps = await Future.wait(futures);

    /// Filter invalid packages
    return apps.where((app) {
      if (app.packageName.isEmpty) return false;
      if (app.packageName == 'android') return false;
      return true;
    }).toList();
  }

  String? _safeInstallerPackage(Application app) {
    try {
      final d = app as dynamic;
      final val = d.installerPackageName as String?;

      if (val == null) return null;

      if (val.contains('vending')) return 'play_store';

      return val;
    } catch (_) {
      return null;
    }
  }

  List<String> _safePermissions(Application app) {
    try {
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
