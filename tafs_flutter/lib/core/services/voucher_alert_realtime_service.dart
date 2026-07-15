import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../../features/auth/domain/entities/student.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../features/fee_ledger/presentation/bloc/fee_summary_event.dart';
import '../../features/notice_board/presentation/utils/notice_board_realtime.dart';
import '../../features/notice_board/presentation/bloc/notice_board_event.dart';
import '../../injection_container.dart';
import '../navigation/app_navigator.dart';
import 'voucher_alert_banner_helper.dart';

/// Listens for voucher alerts over the parent chat socket for the whole login
/// session (not tied to [MainShellPage] lifecycle).
class VoucherAlertRealtimeService {
  VoucherAlertRealtimeService._();

  static final VoucherAlertRealtimeService instance = VoucherAlertRealtimeService._();

  StreamSubscription<Map<String, dynamic>>? _voucherSub;
  StreamSubscription<void>? _connectSub;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _voucherSub = InjectionContainer.chatRepository.onVoucherAlertPayload.listen(_onPayload);
    _connectSub = InjectionContainer.chatRepository.onConnect.listen((_) {
      InjectionContainer.noticeBoardBloc.add(const NoticeBoardRefreshRequested());
    });
  }

  void stop() {
    _voucherSub?.cancel();
    _connectSub?.cancel();
    _voucherSub = null;
    _connectSub = null;
    _started = false;
    VoucherAlertBannerHelper.resetSession();
  }

  void _onPayload(Map<String, dynamic> data) {
    _applyToFeed(data);
    _showBanner(data);
    _reloadFees();
  }

  void _applyToFeed(Map<String, dynamic> data) {
    final authState = InjectionContainer.authBloc.state;
    if (authState is! AuthAuthenticated) {
      InjectionContainer.noticeBoardBloc.add(const NoticeBoardRefreshRequested());
      return;
    }

    applyVoucherAlertRealtime(
      InjectionContainer.noticeBoardBloc,
      data,
      familyId: authState.parent.id,
      studentName: _studentNameForCc(authState.parent.students, data['student_cc']),
    );
  }

  void _showBanner(Map<String, dynamic> data) {
    void attempt() {
      final context = appNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      VoucherAlertBannerHelper.showFromRealtime(
        context,
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
        studentCc: data['student_cc'],
        alertType: data['alert_type'] as String?,
        voucherId: data['voucher_id'],
        alertId: data['id'],
      );
    }

    // Same race as FCM: context can be non-null while Overlay insert is unsafe.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      attempt();
      if (appNavigatorKey.currentContext == null) {
        Future<void>.delayed(const Duration(milliseconds: 300), attempt);
      }
    });
  }

  void _reloadFees() {
    final student = InjectionContainer.selectedStudentCubit.state;
    if (student == null) return;

    InjectionContainer.feeSummaryBloc.add(FeeSummaryLoadRequested(student.cc));
    InjectionContainer.feeLedgerBloc.add(FeeLedgerLoadRequested(student.cc));
  }

  String _studentNameForCc(List<Student> students, Object? studentCcRaw) {
    final studentCc = _parseInt(studentCcRaw);
    if (studentCc == null) return 'Student';

    final selected = InjectionContainer.selectedStudentCubit.state;
    if (selected != null && selected.cc == studentCc) {
      return selected.fullName;
    }

    for (final student in students) {
      if (student.cc == studentCc) return student.fullName;
    }
    return 'Student';
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
