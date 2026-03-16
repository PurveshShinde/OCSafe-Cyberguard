import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Request notification permission (Android 13+)
  Future<void> requestPermission() async {
    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
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
