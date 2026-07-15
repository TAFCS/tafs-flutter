import 'package:flutter/material.dart';
import '../navigation/app_navigator.dart';
import 'in_app_notification_service.dart';
import '../../features/notice_board/domain/entities/voucher_alert.dart';
import '../../injection_container.dart';

/// Shows the floating in-app banner (same UI as support-ticket messages)
/// when a new voucher alert arrives.
class VoucherAlertBannerHelper {
  VoucherAlertBannerHelper._();

  static final Set<int> _shownAlertIds = {};
  static final Set<String> _shownFcmKeys = {};

  /// Clear dedupe state (e.g. after test data reset).
  static void resetSession() {
    _shownAlertIds.clear();
    _shownFcmKeys.clear();
  }

  static void maybeShowForAlerts(BuildContext context, List<VoucherAlert> alerts) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 3));
    final fresh = alerts
        .where((a) => !a.isRead && a.createdAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final alert in fresh) {
      if (!_shownAlertIds.add(alert.id)) continue;
      _show(context, alert);
      break;
    }
  }

  static void showNewAlerts(BuildContext context, List<VoucherAlert> alerts) {
    final sorted = [...alerts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final alert in sorted) {
      if (alert.isRead) continue;

      final fcmKey = '${alert.voucherId}_${alert.alertType}';
      if (_shownFcmKeys.contains(fcmKey)) {
        _shownAlertIds.add(alert.id);
        continue;
      }
      if (!_shownAlertIds.add(alert.id)) continue;

      _show(context, alert);
      break;
    }
  }

  static void showFromFcm(
    BuildContext context, {
    required String title,
    required String body,
    required Object? studentCc,
    String? alertType,
    Object? voucherId,
    Object? alertId,
  }) {
    showFromRealtime(
      context,
      title: title,
      body: body,
      studentCc: studentCc,
      alertType: alertType,
      voucherId: voucherId,
      alertId: alertId,
    );
  }

  /// Socket / foreground FCM — always attempt to show (no throttle).
  static bool showFromRealtime(
    BuildContext context, {
    required String title,
    required String body,
    required Object? studentCc,
    String? alertType,
    Object? voucherId,
    Object? alertId,
  }) {
    final parsedAlertId = _parseInt(alertId);
    if (parsedAlertId != null && _shownAlertIds.contains(parsedAlertId)) {
      return false;
    }

    final fcmKey = '${voucherId ?? ''}_${alertType ?? ''}';
    if (voucherId != null &&
        alertType != null &&
        !_shownFcmKeys.add(fcmKey)) {
      return false;
    }

    final preview = body.length > 80 ? '${body.substring(0, 80)}…' : body;
    final displayTitle = _displayTitle(title, alertType);
    final displayBody = preview.isNotEmpty
        ? preview
        : _fallbackBody(alertType);

    final shown = InAppNotificationService.show(
      context: context,
      title: displayTitle,
      message: displayBody,
      onTap: () => _openFees(studentCc),
    );
    if (!shown) {
      // Don't mark dedupe keys if the overlay insert failed — allow retry.
      if (voucherId != null && alertType != null) {
        _shownFcmKeys.remove(fcmKey);
      }
      return false;
    }

    if (parsedAlertId != null) {
      _shownAlertIds.add(parsedAlertId);
    }
    return true;
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static void _show(BuildContext context, VoucherAlert alert) {
    final preview = alert.body.length > 80 ? '${alert.body.substring(0, 80)}…' : alert.body;
    InAppNotificationService.show(
      context: context,
      title: alert.title,
      message: preview,
      onTap: () => _openFees(alert.studentCc),
    );
  }

  static String _displayTitle(String title, String? alertType) {
    if (title.isNotEmpty && title != 'Notification') return title;
    if (alertType == 'VOUCHER_ISSUED') return 'School Fees';
    if (alertType == 'BECAME_OVERDUE') return 'Fee Overdue';
    if (alertType?.startsWith('EXPIRY_REMINDER_') == true) return 'Payment Deadline';
    if (alertType?.startsWith('DUE_REMINDER_') == true) return 'Fee Reminder';
    return 'Fee Reminder';
  }

  static String _fallbackBody(String? alertType) {
    if (alertType == 'VOUCHER_ISSUED') {
      return 'School fees are ready to pay. Tap to view details.';
    }
    return 'You have an update about school fees. Tap to view.';
  }

  static void _openFees(Object? studentCc) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final parsedCc = studentCc != null ? int.tryParse(studentCc.toString()) : null;
    final activeStudent = InjectionContainer.selectedStudentCubit.state;
    if (activeStudent == null || (parsedCc != null && activeStudent.cc != parsedCc)) return;

    switchToFeesTab();
  }
}
