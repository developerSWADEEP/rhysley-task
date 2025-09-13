import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permission
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }

      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      _initialized = true;
      print("✅ Notification service initialized successfully");
    } catch (e) {
      print("❌ Error initializing notification service: $e");
    }
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rhysley_location_channel',
      'Rhysley Location Updates',
      description: 'Notifications for location tracking updates',
      importance: Importance.high,
      // priority: Priority.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showLocationNotification({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
  }) async {
    try {
      await initialize();

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rhysley_location_channel',
        'Rhysley Location Updates',
        channelDescription: 'Real-time location tracking updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2196F3),
        enableVibration: true,
        playSound: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        styleInformation: BigTextStyleInformation(
          '📍 New Location Update\n'
          'Latitude: ${latitude.toStringAsFixed(6)}\n'
          'Longitude: ${longitude.toStringAsFixed(6)}\n'
          'Accuracy: ${accuracy.toStringAsFixed(1)}m\n'
          'Speed: ${speed.toStringAsFixed(1)} m/s',
          contentTitle: 'Location Updated',
          htmlFormatBigText: true,
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use timestamp as notification ID to ensure uniqueness
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notifications.show(
        notificationId,
        '📍 Location Updated',
        'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
        notificationDetails,
      );

      print("✅ Location notification sent: ID $notificationId");
    } catch (e) {
      print("❌ Error showing location notification: $e");
    }
  }

  static Future<void> showServiceStatusNotification({
    required String title,
    required String message,
    required bool isRunning,
  }) async {
    try {
      await initialize();

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rhysley_service_channel',
        'Rhysley Service Status',
        channelDescription: 'Background service status updates',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: isRunning ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        enableVibration: true,
        playSound: true,
        ongoing: isRunning, // Make it ongoing if service is running
        autoCancel: !isRunning, // Don't auto-cancel if service is running
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        isRunning ? 999 : 998, // Use different IDs for running/stopped
        title,
        message,
        notificationDetails,
      );

      print("✅ Service status notification sent: $title");
    } catch (e) {
      print("❌ Error showing service status notification: $e");
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print("✅ All notifications cancelled");
    } catch (e) {
      print("❌ Error cancelling notifications: $e");
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print("✅ Notification $id cancelled");
    } catch (e) {
      print("❌ Error cancelling notification $id: $e");
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print("🔔 Notification tapped: ${response.payload}");
    // Handle notification tap if needed
  }
}
