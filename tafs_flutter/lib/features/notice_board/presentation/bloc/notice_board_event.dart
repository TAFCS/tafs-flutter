import 'package:equatable/equatable.dart';
import '../../domain/entities/voucher_alert.dart';

abstract class NoticeBoardEvent extends Equatable {
  const NoticeBoardEvent();

  @override
  List<Object?> get props => [];
}

class NoticeBoardLoadRequested extends NoticeBoardEvent {
  const NoticeBoardLoadRequested();
}

/// Refetch feed without clearing the UI (stale-while-revalidate).
class NoticeBoardRefreshRequested extends NoticeBoardEvent {
  const NoticeBoardRefreshRequested();
}

/// Insert a voucher alert pushed over socket / FCM before the API round-trip.
class NoticeBoardVoucherAlertReceived extends NoticeBoardEvent {
  final VoucherAlert alert;

  const NoticeBoardVoucherAlertReceived(this.alert);

  @override
  List<Object?> get props => [alert];
}

class NoticeBoardNextPageRequested extends NoticeBoardEvent {
  final int cursor;
  const NoticeBoardNextPageRequested(this.cursor);

  @override
  List<Object?> get props => [cursor];
}

class NoticeBoardPostRead extends NoticeBoardEvent {
  final int postId;
  const NoticeBoardPostRead(this.postId);

  @override
  List<Object?> get props => [postId];
}

class NoticeBoardAlertRead extends NoticeBoardEvent {
  final int alertId;
  const NoticeBoardAlertRead(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class NoticeBoardCalendarAlertRead extends NoticeBoardEvent {
  final int alertId;
  const NoticeBoardCalendarAlertRead(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class NoticeBoardVoucherAlertRead extends NoticeBoardEvent {
  final int alertId;
  const NoticeBoardVoucherAlertRead(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class NoticeBoardResetRequested extends NoticeBoardEvent {
  const NoticeBoardResetRequested();
}
