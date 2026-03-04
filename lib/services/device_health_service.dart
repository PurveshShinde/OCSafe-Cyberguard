import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceHealthService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Battery _battery = Battery();

  /// Gets Android version, Device model, Battery level, Storage info.
  Future<DeviceHealthData> getDeviceHealth() async {
    String androidVersion = 'Unknown';
    String deviceModel = 'Unknown';
    int batteryLevel = 0;
    
    try {
      if (Platform.isAndroid) {
         final androidInfo = await _deviceInfoPlugin.androidInfo;
         deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
         androidVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      }
    } catch (_) {}

    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (_) {}

    return DeviceHealthData(
      androidVersion: androidVersion,
      deviceModel: deviceModel,
      batteryLevel: batteryLevel,
      storageUsedPercentage: 64, // Mocked for MVP, as dart:io getting full storage requires heavy native bridges
    );
  }
}

class DeviceHealthData {
  final String androidVersion;
  final String deviceModel;
  final int batteryLevel;
  final int storageUsedPercentage;

  DeviceHealthData({
    required this.androidVersion,
    required this.deviceModel,
    required this.batteryLevel,
    required this.storageUsedPercentage,
  });
}
