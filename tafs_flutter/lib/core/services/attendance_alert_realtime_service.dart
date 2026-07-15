import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../features/attendance_history/presentation/pages/attendance_calendar_page.dart';
import '../../features/notice_board/presentation/bloc/notice_board_event.dart';
import '../../injection_container.dart';
import '../navigation/app_navigator.dart';
import 'in_app_notification_service.dart';

/// Live clock-in / clock-out alerts over the chat socket (same pattern as
/// [NoticeBoardRealtimeService]). Refreshes the home feed and shows an in-app
/// banner while the parent app is open.
class AttendanceAlertRealtimeService {
  AttendanceAlertRealtimeService._();

  static final AttendanceAlertRealtimeService instance =
      AttendanceAlertRealtimeService._();

  StreamSubscription<Map<String, dynamic>>? _alertSub;
  bool _started = false;
  final Set<int> _shownAlertIds = {};

  void start() {
    if (_started) return;
    _started = true;

    _alertSub = InjectionContainer.chatRepository.onAttendanceAlertPayload
        .listen(_onPayload);
  }

  void stop() {
    _alertSub?.cancel();
    _alertSub = null;
    _started = false;
    _shownAlertIds.clear();
  }

  void _onPayload(Map<String, dynamic> data) {
    handleIncoming(
      title: data['title'] as String?,
      body: data['body'] as String?,
      alertId: data['id'],
      studentCc: data['student_cc'],
      scanTime: data['scan_time'],
    );
  }

  /// Shared entry for socket + foreground FCM.
  void handleIncoming({
    String? title,
    String? body,
    Object? alertId,
    Object? studentCc,
    Object? scanTime,
  }) {
    InjectionContainer.noticeBoardBloc
        .add(const NoticeBoardRefreshRequested());
    _showBanner(
      title: title,
      body: body,
      alertId: alertId,
      studentCc: studentCc,
      scanTime: scanTime,
    );
  }

  void _showBanner({
    String? title,
    String? body,
    Object? alertId,
    Object? studentCc,
    Object? scanTime,
  }) {
    final parsedAlertId = _parseInt(alertId);
    if (parsedAlertId != null && !_shownAlertIds.add(parsedAlertId)) return;

    final trimmedTitle = title?.trim();
    final trimmedBody = body?.trim() ?? '';
    final displayTitle = (trimmedTitle != null && trimmedTitle.isNotEmpty)
        ? trimmedTitle
        : 'Attendance update';
    final preview = trimmedBody.length > 80
        ? '${trimmedBody.substring(0, 80)}…'
        : trimmedBody;

    void attempt() {
      InAppNotificationService.show(
        title: displayTitle,
        message: preview.isNotEmpty
            ? preview
            : 'Tap to view attendance details.',
        onTap: () => _openAttendance(
          studentCc: studentCc,
          scanTime: scanTime,
        ),
      );
    }

    // Schedule after the current frame so the host has settled if a rebuild
    // (e.g. feed refresh) is already in progress.
    SchedulerBinding.instance.addPostFrameCallback((_) => attempt());
  }

  void _openAttendance({Object? studentCc, Object? scanTime}) {
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      switchToHomeTab();
      return;
    }

    final parsedCc =
        studentCc != null ? int.tryParse(studentCc.toString()) : null;
    final activeStudent = InjectionContainer.selectedStudentCubit.state;
    if (activeStudent == null ||
        (parsedCc != null && activeStudent.cc != parsedCc)) {
      switchToHomeTab();
      return;
    }

    final parsedDate =
        scanTime != null ? DateTime.tryParse(scanTime.toString()) : null;

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

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
