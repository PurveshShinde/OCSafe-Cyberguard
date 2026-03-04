import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for getting device health and optimization data.
class OptimizationService {
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Gets the current battery level (0-100).
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return -1;
    }
  }

  /// Gets the battery state (charging, discharging, etc).
  Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (e) {
      return BatteryState.unknown;
    }
  }

  /// Gets Android device information.
  Future<DeviceData> getDeviceInfo() async {
    try {
      final info = await _deviceInfo.androidInfo;
      return DeviceData(
        model: info.model,
        brand: info.brand,
        androidVersion: info.version.release,
        sdkVersion: info.version.sdkInt.toString(),
        manufacturer: info.manufacturer,
        device: info.device,
        isPhysicalDevice: info.isPhysicalDevice,
      );
    } catch (e) {
      return const DeviceData(
        model: 'Unknown',
        brand: 'Unknown',
        androidVersion: 'Unknown',
        sdkVersion: 'Unknown',
        manufacturer: 'Unknown',
        device: 'Unknown',
        isPhysicalDevice: false,
      );
    }
  }
}

/// Structured device information.
class DeviceData {
  final String model;
  final String brand;
  final String androidVersion;
  final String sdkVersion;
  final String manufacturer;
  final String device;
  final bool isPhysicalDevice;

  const DeviceData({
    required this.model,
    required this.brand,
    required this.androidVersion,
    required this.sdkVersion,
    required this.manufacturer,
    required this.device,
    required this.isPhysicalDevice,
  });
}
