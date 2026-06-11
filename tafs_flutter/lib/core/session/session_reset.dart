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
import '../../features/chat/staff/presentation/bloc/staff_announcements_cubit.dart';
import '../../features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../features/fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../features/fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import '../../features/fee_ledger/presentation/bloc/fee_summary_event.dart';
import '../../features/fee_ledger/presentation/bloc/student_ledger_bloc.dart';
import '../../features/fee_ledger/presentation/bloc/student_ledger_event.dart';
import '../../features/notice_board/presentation/bloc/notice_board_bloc.dart';
import '../../features/notice_board/presentation/bloc/notice_board_event.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';

/// Clears session-scoped UI state when the parent logs out.
void resetSessionState(BuildContext context) {
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
  context.read<StaffTicketQueueBloc>().add(StaffQueueReset());
  context.read<StaffPendingApprovalsCubit>().reset();
  context.read<StaffAnnouncementsCubit>().reset();
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
