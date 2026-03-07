import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {},
    );

    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  Future<void> showThreatDetectedNotification(Threat threat) async {
    final String reasonsSummary = threat.reasons.take(2).join(', ');
    
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'malware_alert_channel',
      'Threat Detected',
      channelDescription: 'High priority alerts for detected malware',
      importance: Importance.max,
      priority: Priority.max,
      color: const Color(0xFFEF4444), // Octane Red
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction('uninstall', 'Uninstall', cancelNotification: true),
        AndroidNotificationAction('ignore', 'Ignore', cancelNotification: true),
      ],
    );
    
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      id: threat.packageName.hashCode,
      title: 'Shield Alert: Threat Detected',
      body: 'App: ${threat.packageName}\nReason: $reasonsSummary',
      notificationDetails: platformChannelSpecifics,
    );
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
      color: Color(0xFFF59E0B), // Octane Warning
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

  Future<void> showInfoNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'info_channel',
      'Security Updates',
      channelDescription: 'General scanner info and medium risks',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF0A6BFF), // Octane Blue
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
