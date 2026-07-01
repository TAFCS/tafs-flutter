import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../features/notice_board/data/datasources/notice_board_remote_data_source.dart';
import '../../features/notice_board/domain/entities/voucher_alert.dart';
import '../../features/notice_board/presentation/bloc/notice_board_event.dart';
import '../../injection_container.dart';
import 'voucher_alert_banner_helper.dart';

/// Polls for new voucher alerts while the parent app is open (backup when
/// socket push is delayed). Primary delivery is `voucherAlertReceived` socket.
class VoucherAlertWatcher {
  VoucherAlertWatcher._();
  static final VoucherAlertWatcher instance = VoucherAlertWatcher._();

  Timer? _timer;
  BuildContext? _hostContext;
  final Set<int> _knownIds = {};
  bool _primed = false;

  static const _pollInterval = Duration(seconds: 3);

  void start(BuildContext hostContext) {
    _hostContext = hostContext;
    _timer?.cancel();
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _hostContext = null;
  }

  /// Align poll baseline with the notice board feed (avoids swallowing new alerts).
  void syncBaseline(Set<int> ids) {
    _knownIds
      ..clear()
      ..addAll(ids);
    _primed = true;
  }

  void resetBaseline() {
    _knownIds.clear();
    _primed = false;
    VoucherAlertBannerHelper.resetSession();
  }

  Future<void> _poll() async {
    final host = _hostContext;
    if (host == null || !host.mounted) return;

    try {
      final alerts = await NoticeBoardRemoteDataSource(InjectionContainer.dio)
          .getVoucherAlerts();

      final currentIds = alerts.map((a) => a.id).toSet();

      if (!_primed) {
        _knownIds.addAll(currentIds);
        _primed = true;
        return;
      }

      final brandNew = alerts.where((a) => !_knownIds.contains(a.id)).toList();
      if (brandNew.isEmpty) return;

      _knownIds.addAll(brandNew.map((a) => a.id));

      final unreadNew = brandNew.where((a) => !a.isRead).toList();
      if (unreadNew.isEmpty) return;

      if (!host.mounted) return;
      _showBanner(host, unreadNew);
      InjectionContainer.noticeBoardBloc.add(const NoticeBoardLoadRequested());
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('VoucherAlertWatcher poll failed: $e\n$st');
      }
    }
  }

  void _showBanner(BuildContext host, List<VoucherAlert> unreadNew) {
    void show() {
      if (!host.mounted) return;
      VoucherAlertBannerHelper.showNewAlerts(host, unreadNew);
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      show();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => show());
    }
  }
}
