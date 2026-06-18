import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../navigation/app_navigator.dart';
import 'fcm_registration_service.dart';
import 'in_app_notification_service.dart';
import '../../injection_container.dart';
import '../../features/attendance_history/presentation/pages/attendance_calendar_page.dart';

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
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      
      // Also trigger in-app notification banner if title/body exists and a context is available
      final context = appNavigatorKey.currentContext;
      if (context != null) {
        final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        final type = message.data['type'] as String?;
        final ticketId = message.data['ticketId'] as String?;

        InAppNotificationService.show(
          context: context,
          title: title,
          message: body,
          onTap: () {
            if (type == 'SUPPORT_TICKET_MESSAGE' && ticketId != null && ticketId.isNotEmpty) {
              navigateToSupportTicketThread(ticketId);
            } else if (type == 'ATTENDANCE_ALERT') {
              _handleNotificationRouting(message.data);
            }
          },
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleRemoteMessage(message);
    });
  }

  void _onLocalNotificationTap(fln.NotificationResponse details) {
    if (details.payload == null || details.payload!.isEmpty) return;
    try {
      final data = jsonDecode(details.payload!) as Map<String, dynamic>;
      _handleNotificationRouting(data);
    } catch (_) {}
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _handleNotificationRouting(message.data);
  }

  void _handleNotificationRouting(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    if (type == 'SUPPORT_TICKET_MESSAGE') {
      final ticketId = data['ticketId'] as String?;
      if (ticketId != null && ticketId.isNotEmpty) {
        navigateToSupportTicketThread(ticketId);
      }
    } else if (type == 'ATTENDANCE_ALERT') {
      // Find the context to push the screen
      final context = appNavigatorKey.currentContext;
      if (context != null) {
        final studentCcStr = data['studentCc'] ?? data['student_cc'];
        final studentCc = studentCcStr != null ? int.tryParse(studentCcStr.toString()) : null;
        
        // Grab currently selected student or default
        final activeStudent = InjectionContainer.selectedStudentCubit.state;
        if (activeStudent != null && activeStudent.cc == studentCc) {
          final scanTimeStr = data['scanTime'] ?? data['scan_time'];
          final parsedDate = scanTimeStr != null ? DateTime.tryParse(scanTimeStr.toString()) : null;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceCalendarPage(
                student: activeStudent,
                initialSelectedDate: parsedDate?.toLocal(),
              ),
            ),
          );
        }
      }
    }
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
