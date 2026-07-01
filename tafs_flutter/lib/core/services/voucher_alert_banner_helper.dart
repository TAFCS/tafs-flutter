import 'package:flutter/material.dart';
import '../navigation/app_navigator.dart';
import 'in_app_notification_service.dart';
import '../../features/fee_ledger/presentation/pages/fee_ledger_page.dart';
import '../../features/notice_board/domain/entities/voucher_alert.dart';
import '../../injection_container.dart';

/// Shows the floating in-app banner (same UI as support-ticket messages)
/// when a new voucher alert arrives.
class VoucherAlertBannerHelper {
  VoucherAlertBannerHelper._();

  static final Set<int> _shownAlertIds = {};
  static final Set<String> _shownFcmKeys = {};
  static DateTime? _lastBannerShownAt;

  /// Clear dedupe state (e.g. after test data reset).
  static void resetSession() {
    _shownAlertIds.clear();
    _shownFcmKeys.clear();
    _lastBannerShownAt = null;
  }

  static bool _throttle() {
    final now = DateTime.now();
    if (_lastBannerShownAt != null &&
        now.difference(_lastBannerShownAt!) < const Duration(seconds: 4)) {
      return false;
    }
    _lastBannerShownAt = now;
    return true;
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
  }) {
    final fcmKey = '${voucherId ?? ''}_${alertType ?? ''}';
    if (voucherId != null && alertType != null && !_shownFcmKeys.add(fcmKey)) {
      return;
    }
    if (!_throttle()) return;

    final preview = body.length > 80 ? '${body.substring(0, 80)}…' : body;
    final displayTitle = _displayTitle(title, alertType);
    final displayBody = preview.isNotEmpty
        ? preview
        : _fallbackBody(alertType);

    InAppNotificationService.show(
      context: context,
      title: displayTitle,
      message: displayBody,
      onTap: () => _openFees(studentCc),
    );
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
    if (alertType == 'VOUCHER_ISSUED') return 'New Fee Challan';
    if (alertType == 'BECAME_OVERDUE') return 'Fee Overdue';
    if (alertType?.startsWith('EXPIRY_REMINDER_') == true) return 'Voucher Expiring Soon';
    if (alertType?.startsWith('DUE_REMINDER_') == true) return 'Fee Due Soon';
    return 'Fee Reminder';
  }

  static String _fallbackBody(String? alertType) {
    if (alertType == 'VOUCHER_ISSUED') {
      return 'Your fee challan is ready. Tap to view and pay.';
    }
    return 'You have an update about your fee voucher. Tap to view.';
  }

  static void _openFees(Object? studentCc) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final parsedCc = studentCc != null ? int.tryParse(studentCc.toString()) : null;
    final activeStudent = InjectionContainer.selectedStudentCubit.state;
    if (activeStudent == null || (parsedCc != null && activeStudent.cc != parsedCc)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeeLedgerPage(
          studentCc: activeStudent.cc,
          studentName: activeStudent.fullName,
        ),
      ),
    );
  }
}
