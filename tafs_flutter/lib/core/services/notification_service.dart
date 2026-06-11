import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'dart:convert';
import 'dart:io';

import '../navigation/app_navigator.dart';
import 'fcm_registration_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _androidNotificationIcon = 'ic_notification';

  final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await FcmRegistrationService.instance.requestAndroidPermission();

    const fln.AndroidInitializationSettings androidSettings =
        fln.AndroidInitializationSettings(_androidNotificationIcon);

    const fln.DarwinInitializationSettings iosSettings =
        fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const fln.InitializationSettings initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: fln.Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void setupInteractions() {
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleRemoteMessage(message);
    });
  }

  void _onLocalNotificationTap(fln.NotificationResponse details) {
    if (details.payload == null || details.payload!.isEmpty) return;
    try {
      final data = jsonDecode(details.payload!) as Map<String, dynamic>;
      _openSupportTicketFromData(data);
    } catch (_) {}
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _openSupportTicketFromData(message.data);
  }

  void _openSupportTicketFromData(Map<String, dynamic> data) {
    if (data['type'] != 'SUPPORT_TICKET_MESSAGE') return;
    final ticketId = data['ticketId'] as String?;
    if (ticketId == null || ticketId.isEmpty) return;
    navigateToSupportTicketThread(ticketId);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          icon: android?.smallIcon ?? _androidNotificationIcon,
          // Ensures heads-up on pre-Oreo devices that ignore channels.
          ticker: title ?? body,
        ),
        iOS: const fln.DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
