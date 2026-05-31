import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Must match a file in android/app/src/main/res/drawable/ (not mipmap).
  static const String _androidNotificationIcon = 'ic_notification';

  final fln.FlutterLocalNotificationsPlugin _localNotifications = fln.FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Android Settings — drawable resource name only (no @drawable/ prefix).
    const fln.AndroidInitializationSettings androidSettings =
        fln.AndroidInitializationSettings(_androidNotificationIcon);

    // 2. iOS Settings
    const fln.DarwinInitializationSettings iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 3. Initialization
    const fln.InitializationSettings initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );

    // Create Android High Importance Channel
    if (Platform.isAndroid) {
      const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: fln.Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void setupInteractions() {
    // 1. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 2. Background/Killed state interaction
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app: ${message.data}');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: android?.smallIcon ?? _androidNotificationIcon,
          ),
          iOS: const fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
