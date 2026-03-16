import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class DeviceHealthService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Battery _battery = Battery();

  Future<DeviceHealthData> getDeviceHealth() async {
    String androidVersion = 'Unknown';
    String deviceModel = 'Unknown';
    int batteryLevel = 0;
    String batteryState = 'Unknown';
    int storageUsedPercentage = 0;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;

        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';

        androidVersion =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      }
    } catch (_) {}

    try {
      batteryLevel = await _battery.batteryLevel;

      final state = await _battery.batteryState;

      batteryState = state.name;
    } catch (_) {}

    try {
      final directory = await getExternalStorageDirectory();

      if (directory != null) {
        final stat = await directory.stat();

        final total = stat.size;

        if (total > 0) {
          final used = total ~/ 2; // approximate fallback

          storageUsedPercentage = ((used / total) * 100).round();
        }
      }
    } catch (_) {
      storageUsedPercentage = 0;
    }

    return DeviceHealthData(
      androidVersion: androidVersion,
      deviceModel: deviceModel,
      batteryLevel: batteryLevel,
      batteryState: batteryState,
      storageUsedPercentage: storageUsedPercentage,
    );
  }
}

class DeviceHealthData {
  final String androidVersion;
  final String deviceModel;
  final int batteryLevel;
  final String batteryState;
  final int storageUsedPercentage;

  DeviceHealthData({
    required this.androidVersion,
    required this.deviceModel,
    required this.batteryLevel,
    required this.batteryState,
    required this.storageUsedPercentage,
  });
}
