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

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'UNINSTALL' && response.payload != null) {
          try {
            await UninstallService.uninstallApp(response.payload!);
          } catch (e) {
            debugPrint('Failed to trigger uninstall: $e');
          }
        }
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  static const MethodChannel _nativeChannel = MethodChannel('com.ocsafe.cyberguard/background');

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

  Future<void> cancelWarningNotification(String appName) async {
    try {
      await _nativeChannel.invokeMethod('cancel_malware_notification', {
        'app_name': appName,
      });
    } catch (e) {
      debugPrint('Failed to cancel native malware notification: $e');
    }
  }

  Future<void> showSafeBrowsingNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'safe_browsing_channel',
      'Safe Browsing Alerts',
      channelDescription: 'Alerts for malicious or phishing websites',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFB8C00), // Orange color for warnings
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
