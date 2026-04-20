import 'package:device_apps/device_apps.dart';

void main() async {
  final app = await DeviceApps.getApp('org.fdroid.fdroid', true);
  if (app != null) {
    dynamic d = app;
    print(d.requestedPermissions);
    try {
      print(d.permissions);
    } catch (_) {}
  }
}
 