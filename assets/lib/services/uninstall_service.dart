import 'package:flutter/services.dart';

class UninstallService {
  static const MethodChannel _channel = MethodChannel('com.ocsafe.cyberguard/uninstall');

  /// Prompts the Android OS to uninstall the given package.
  /// Throws PlatformException if it fails.
  static Future<void> uninstallApp(String packageName) async {
    try {
      await _channel.invokeMethod('uninstall_app', {
        'package_name': packageName,
      });
    } on PlatformException catch (e) {
      throw Exception("Failed to trigger uninstall: '${e.message}'.");
    }
  }
}
