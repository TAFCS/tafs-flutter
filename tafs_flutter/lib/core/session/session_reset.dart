import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/student.dart';
import '../../features/auth/presentation/bloc/selected_student_cubit.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_event.dart';
import '../../features/support_tickets/presentation/bloc/support_ticket_list_bloc.dart';
import '../../features/support_tickets/presentation/bloc/support_ticket_list_event.dart';
import '../../features/support_tickets/staff/presentation/bloc/staff_pending_approvals_cubit.dart';
import '../../features/support_tickets/staff/presentation/bloc/staff_ticket_queue_bloc.dart';
import '../../features/notice_board/staff/presentation/bloc/staff_notice_board_cubit.dart';
import '../../features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../features/fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../features/fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import '../../features/fee_ledger/presentation/bloc/fee_summary_event.dart';
import '../../features/fee_ledger/presentation/bloc/student_ledger_bloc.dart';
import '../../features/fee_ledger/presentation/bloc/student_ledger_event.dart';
import '../../features/notice_board/presentation/bloc/notice_board_bloc.dart';
import '../services/voucher_alert_realtime_service.dart';
import '../services/notice_board_realtime_service.dart';
import '../services/attendance_alert_realtime_service.dart';
import '../services/notification_service.dart';
import '../../features/notice_board/presentation/bloc/notice_board_event.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';

/// Clears session-scoped UI state when the parent logs out.
void resetSessionState(BuildContext context) {
  VoucherAlertRealtimeService.instance.stop();
  NoticeBoardRealtimeService.instance.stop();
  AttendanceAlertRealtimeService.instance.stop();
  unawaited(NotificationService().clearDeliveredNotifications());
  context.read<SelectedStudentCubit>().clear();
  context.read<FeeLedgerBloc>().add(const FeeLedgerResetRequested());
  context.read<FeeSummaryBloc>().add(const FeeSummaryResetRequested());
  context.read<StudentLedgerBloc>().add(const StudentLedgerResetRequested());
  context.read<NoticeBoardBloc>().add(const NoticeBoardResetRequested());
  context.read<ProfileBloc>().add(const ProfileResetRequested());
  context.read<ChatBloc>().add(ChatSessionStopRequested());
  context.read<SupportTicketListBloc>().add(const SupportTicketListResetRequested());
}

/// Clears staff support-ticket state on staff logout.
void resetStaffSessionState(BuildContext context) {
  unawaited(NotificationService().clearDeliveredNotifications());
  context.read<StaffTicketQueueBloc>().add(StaffQueueReset());
  context.read<StaffPendingApprovalsCubit>().reset();
  context.read<StaffNoticeBoardCubit>().reset();
  context.read<ChatBloc>().add(ChatSessionStopRequested());
}

/// Keeps [SelectedStudentCubit] aligned with the authenticated student list.
void syncSelectedStudent(BuildContext context, List<Student> students) {
  final cubit = context.read<SelectedStudentCubit>();
  final current = cubit.state;
  if (current == null) return;

  Student? match;
  for (final student in students) {
    if (student.cc == current.cc) {
      match = student;
      break;
    }
  }

  if (match == null) {
    cubit.clear();
  } else {
    cubit.select(match);
  }
}
