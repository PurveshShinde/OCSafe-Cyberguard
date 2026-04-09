import 'package:flutter/services.dart';
import 'theft_constants.dart';

/// Flutter-to-Android platform channel bridge for device locking.
///
/// All calls are wrapped in try/catch so failures never propagate
/// as unhandled exceptions — graceful degradation by design.
class DeviceLockChannel {
  DeviceLockChannel._();

  static const MethodChannel _channel =
      MethodChannel(TheftConstants.channelName);

  /// Attempts to lock the device immediately via Device Policy Manager.
  /// Silently no-ops if admin permission is not granted.
  static Future<void> lockDevice() async {
    try {
      await _channel.invokeMethod<void>('lockDevice');
    } catch (e) {
      // Ignore — admin may not be active, or platform channel unavailable.
      // ignore: avoid_print
      print('[TheftShield] Lock failed (graceful): $e');
    }
  }

  /// Returns whether Device Admin is currently active for this app.
  /// Used to display the correct UI state.
  static Future<bool> isAdminActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAdminActive');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the Android system dialog asking the user to grant Device Admin.
  static Future<void> requestAdminPermission() async {
    try {
      await _channel.invokeMethod<void>('requestAdminPermission');
    } catch (e) {
      // ignore: avoid_print
      print('[TheftShield] Could not open admin permission dialog: $e');
    }
  }
}
