import '../../data/models/voucher_alert_dto.dart';
import '../bloc/notice_board_bloc.dart';
import '../bloc/notice_board_event.dart';

/// Apply a socket / FCM voucher payload to the home feed immediately, then
/// reconcile with the API in the background.
void applyVoucherAlertRealtime(
  NoticeBoardBloc bloc,
  Map<String, dynamic> data, {
  required int familyId,
  String studentName = 'Student',
}) {
  final alert = VoucherAlertDto.fromRealtimePayload(
    data,
    familyId: familyId,
    studentName: studentName,
  );
  if (alert != null) {
    bloc.add(NoticeBoardVoucherAlertReceived(alert));
  }
  bloc.add(const NoticeBoardRefreshRequested());
}
