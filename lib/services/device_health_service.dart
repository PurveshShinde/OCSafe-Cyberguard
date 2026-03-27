import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ocsafe_cyberguard/services/cache_cleaner_service.dart';

class DeviceHealthService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Battery _battery = Battery();

  Future<DeviceHealthData> getDeviceHealth() async {
    String androidVersion = 'Unknown';
    String deviceModel = 'Unknown';
    int batteryLevel = 0;
    String batteryState = 'Unknown';
    int storageUsedPercentage = 0;
    
    // Start cache calculation asynchronously to not block other metrics
    final cacheFuture = CacheCleanerService().getCacheSize();

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

    double cacheSizeMB = 0.0;
    try {
      final cacheResult = await cacheFuture;
      cacheSizeMB = cacheResult['sizeMB'] as double;
    } catch (_) {}

    // Calculate a composite health score based on metrics
    int healthScore = 100;
    if (batteryLevel < 20 && batteryLevel > 0) healthScore -= 10;
    if (storageUsedPercentage > 90) healthScore -= 15;
    else if (storageUsedPercentage > 80) healthScore -= 5;
    
    // Impact of junk cache on health
    if (cacheSizeMB > 500) healthScore -= 15;
    else if (cacheSizeMB > 100) healthScore -= 5;
    else if (cacheSizeMB == 0) healthScore = (healthScore + 5).clamp(0, 100);

    return DeviceHealthData(
      androidVersion: androidVersion,
      deviceModel: deviceModel,
      batteryLevel: batteryLevel,
      batteryState: batteryState,
      storageUsedPercentage: storageUsedPercentage,
      cacheSizeMB: cacheSizeMB,
      healthScore: healthScore,
    );
  }
}

class DeviceHealthData {
  final String androidVersion;
  final String deviceModel;
  final int batteryLevel;
  final String batteryState;
  final int storageUsedPercentage;
  final double cacheSizeMB;
  final int healthScore;

  DeviceHealthData({
    required this.androidVersion,
    required this.deviceModel,
    required this.batteryLevel,
    required this.batteryState,
    required this.storageUsedPercentage,
    required this.cacheSizeMB,
    required this.healthScore,
  });
}
