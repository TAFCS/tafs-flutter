import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../navigation/app_navigator.dart';
import 'fcm_registration_service.dart';
import 'in_app_notification_service.dart';
import 'voucher_alert_banner_helper.dart';
import 'notice_board_realtime_service.dart';
import 'attendance_alert_realtime_service.dart';
import '../../injection_container.dart';
import '../../features/attendance_history/presentation/pages/attendance_calendar_page.dart';
import '../../features/notice_board/presentation/bloc/notice_board_event.dart';
import '../../features/notice_board/presentation/utils/notice_board_realtime.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _androidNotificationIcon = 'ic_notification';

  static Future<void> clearBadge() async {}

  Future<void> clearDeliveredNotifications() async {
    try {
      await _localNotifications.cancelAll();
      await clearBadge();
    } catch (_) {}
  }

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
    FirebaseMessaging.onMessage.listen(_deliverForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleRemoteMessage(message);
    });
  }

  bool _sessionAcceptsNotifications() {
    final state = InjectionContainer.authBloc.state;
    return state is AuthAuthenticated || state is AuthAuthenticatedStaff;
  }

  void _deliverForegroundMessage(RemoteMessage message) {
    if (!_sessionAcceptsNotifications()) return;
    _showLocalNotification(message);

    final type = message.data['type'] as String?;
    final title = _resolveTitle(message);
    final body = _resolveBody(message);

    // Notice-board / attendance: refresh feed immediately; banner is scheduled
    // inside the shared realtime helpers (also used by the socket path).
    if (type == 'notice_board') {
      NoticeBoardRealtimeService.instance.handleIncoming(
        title: title,
        body: body,
        postId: message.data['post_id'],
      );
      return;
    }

    if (type == 'biometric_attendance' || type == 'ATTENDANCE_ALERT') {
      AttendanceAlertRealtimeService.instance.handleIncoming(
        title: title,
        body: body,
        alertId: message.data['notification_id'] ?? message.data['id'],
        studentCc: message.data['student_cc'] ?? message.data['studentCc'],
        scanTime: message.data['scan_time'] ??
            message.data['scanTime'] ??
            message.data['date'],
      );
      return;
    }

    // Overlay.insert must happen after the current frame. Doing it immediately
    // often fails mid-build/transition while navigator context is already
    // non-null — and the old "retry only if context == null" path never ran.
    void deliver() {
      final context = appNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final ticketId = message.data['ticketId'] as String?;

      if (type == 'voucher_alert') {
        _applyVoucherAlertToFeed(message.data);
        VoucherAlertBannerHelper.showFromRealtime(
          context,
          title: title,
          body: body,
          studentCc: message.data['student_cc'],
          alertType: message.data['alert_type'] as String?,
          voucherId: message.data['voucher_id'],
          alertId: message.data['notification_id'],
        );
        return;
      }

      InAppNotificationService.show(
        context: context,
        title: title,
        message: body,
        onTap: () {
          if (type == 'SUPPORT_TICKET_MESSAGE' && ticketId != null && ticketId.isNotEmpty) {
            navigateToSupportTicketThread(ticketId);
          } else if (type == 'calendar_alert') {
            _handleNotificationRouting(message.data);
          } else if (type == 'EMPLOYEE_NOTICE') {
            InjectionContainer.employeeNoticeCubit.refresh();
          }
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      deliver();
      // Cold-start / auth-gate races: navigator may still be null after one frame.
      if (appNavigatorKey.currentContext == null) {
        Future<void>.delayed(const Duration(milliseconds: 300), deliver);
      }
    });
  }

  void _onLocalNotificationTap(fln.NotificationResponse details) {
    if (!_sessionAcceptsNotifications()) return;
    if (details.payload == null || details.payload!.isEmpty) return;
    try {
      final data = jsonDecode(details.payload!) as Map<String, dynamic>;
      _handleNotificationRouting(data);
    } catch (_) {}
  }

  void _handleRemoteMessage(RemoteMessage message) {
    if (!_sessionAcceptsNotifications()) return;
    _handleNotificationRouting(message.data);
  }

  String _resolveTitle(RemoteMessage message) {
    return message.notification?.title ??
        message.data['title'] as String? ??
        'Notification';
  }

  String _resolveBody(RemoteMessage message) {
    return message.notification?.body ?? message.data['body'] as String? ?? '';
  }

  void _handleNotificationRouting(Map<String, dynamic> data) {
    if (!_sessionAcceptsNotifications()) return;

    final type = data['type'] as String?;
    
    if (type == 'SUPPORT_TICKET_MESSAGE') {
      final ticketId = data['ticketId'] as String?;
      if (ticketId != null && ticketId.isNotEmpty) {
        navigateToSupportTicketThread(ticketId);
      }
    } else if (type == 'ATTENDANCE_ALERT' || type == 'biometric_attendance' || type == 'calendar_alert') {
      InjectionContainer.noticeBoardBloc.add(const NoticeBoardRefreshRequested());
      _handleAttendanceRouting(data);
    } else if (type == 'voucher_alert') {
      _handleVoucherAlertRouting(studentCcStr: data['student_cc']);
      _applyVoucherAlertToFeed(data);
    } else if (type == 'notice_board') {
      switchToHomeTab();
      InjectionContainer.noticeBoardBloc.add(const NoticeBoardRefreshRequested());
    } else if (type == 'EMPLOYEE_NOTICE') {
      // Refresh the employee notice cubit so the Notices tab is up-to-date
      try {
        InjectionContainer.employeeNoticeCubit.refresh();
      } catch (_) {}
    }
  }

  void _handleAttendanceRouting(Map<String, dynamic> data) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final studentCcStr = data['studentCc'] ?? data['student_cc'];
    final studentCc = studentCcStr != null ? int.tryParse(studentCcStr.toString()) : null;
    final activeStudent = InjectionContainer.selectedStudentCubit.state;
    if (activeStudent == null || activeStudent.cc != studentCc) return;

    final scanTimeStr = data['scanTime'] ?? data['scan_time'] ?? data['date'];
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

  void _handleVoucherAlertRouting({Object? studentCcStr}) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final parsedCc = studentCcStr != null ? int.tryParse(studentCcStr.toString()) : null;
    final activeStudent = InjectionContainer.selectedStudentCubit.state;
    if (activeStudent == null || (parsedCc != null && activeStudent.cc != parsedCc)) return;

    switchToFeesTab();
  }

  void _applyVoucherAlertToFeed(Map<String, dynamic> data) {
    final authState = InjectionContainer.authBloc.state;
    if (authState is! AuthAuthenticated) {
      InjectionContainer.noticeBoardBloc.add(const NoticeBoardRefreshRequested());
      return;
    }

    final studentCcRaw = data['student_cc'];
    final studentCc = studentCcRaw is int
        ? studentCcRaw
        : studentCcRaw is num
            ? studentCcRaw.toInt()
            : int.tryParse(studentCcRaw?.toString() ?? '');

    String studentName = 'Student';
    if (studentCc != null) {
      final selected = InjectionContainer.selectedStudentCubit.state;
      if (selected != null && selected.cc == studentCc) {
        studentName = selected.fullName;
      } else {
        for (final student in authState.parent.students) {
          if (student.cc == studentCc) {
            studentName = student.fullName;
            break;
          }
        }
      }
    }

    applyVoucherAlertRealtime(
      InjectionContainer.noticeBoardBloc,
      data,
      familyId: authState.parent.id,
      studentName: studentName,
    );
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
