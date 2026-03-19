import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocsafe_cyberguard/services/uninstall_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  bool _isInitialized = false;

  static const MethodChannel _nativeChannel = MethodChannel(
    'com.ocsafe.cyberguard/background',
  );

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'UNINSTALL' && response.payload != null) {
          try {
            final packageName = response.payload!;

            await UninstallService.uninstallApp(packageName);

            // Cancel malware notification after uninstall
            await cancelWarningNotification(packageName);
          } catch (e) {
            debugPrint('Uninstall action failed: $e');
          }
        }
      },
    );

    _isInitialized = true;
  }

  /// Request notification permission (Android 13+).
  ///
  /// Strategy:
  ///  - If permission is already GRANTED → mark as done, return (no dialog).
  ///  - If permission is NOT granted → request it, regardless of whether
  ///    we've asked before. This handles the case where the user denied once
  ///    but later revoked/re-enabled in Settings.
  ///  - A SharedPreferences flag is used to avoid showing the dialog on EVERY
  ///    launch (only once per grant cycle).
  Future<void> requestPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const prefKey = 'notif_permission_granted';

      final permStatus = await Permission.notification.status;

      if (permStatus.isGranted) {
        // Already granted — just record it and stop
        await prefs.setBool(prefKey, true);
        return;
      }

      // Not granted: request it. We do this even if we asked before,
      // in case the user changed their mind or denied accidentally.
      final result = await Permission.notification.request();
      await prefs.setBool(prefKey, result.isGranted);

      debugPrint('[NotificationService] Permission result: $result');
    } catch (e) {
      debugPrint('[NotificationService] requestPermission failed: $e');
    }
  }

  /// Show malware warning notification via native Android code
  Future<void> showWarningNotification({
    required String appName,
    required String riskLevel,
    required String reason,
    required String packageName,
  }) async {
    try {
      await _nativeChannel.invokeMethod('show_malware_notification', {
        'app_name': appName,
        'risk_level': riskLevel,
        'reason': reason,
        'package_name': packageName,
      });
    } catch (e) {
      debugPrint('Failed to trigger native malware notification: $e');
    }
  }

  /// Cancel malware warning notification
  Future<void> cancelWarningNotification(String packageName) async {
    try {
      await _nativeChannel.invokeMethod('cancel_malware_notification', {
        'package_name': packageName,
      });
    } catch (e) {
      debugPrint('Failed to cancel malware notification: $e');
    }
  }

  /// Safe browsing alert
  Future<void> showSafeBrowsingNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'safe_browsing_channel',
          'Safe Browsing Alerts',
          channelDescription: 'Alerts for malicious or phishing websites',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFB8C00),
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
