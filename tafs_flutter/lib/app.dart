import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/selected_student_cubit.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/support_tickets/presentation/bloc/support_ticket_list_bloc.dart';
import 'features/support_tickets/staff/presentation/bloc/staff_pending_approvals_cubit.dart';
import 'features/support_tickets/staff/presentation/bloc/staff_ticket_queue_bloc.dart';
import 'features/chat/staff/presentation/bloc/staff_announcements_cubit.dart';
import 'features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import 'features/fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import 'features/fee_ledger/presentation/bloc/student_ledger_bloc.dart';
import 'features/notice_board/presentation/bloc/notice_board_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/attendance_history/presentation/bloc/attendance_history_bloc.dart';
import 'injection_container.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => InjectionContainer.authBloc,
        ),
        BlocProvider<FeeLedgerBloc>(
          create: (_) => InjectionContainer.feeLedgerBloc,
        ),
        BlocProvider<FeeSummaryBloc>(
          create: (_) => InjectionContainer.feeSummaryBloc,
        ),
        BlocProvider<StudentLedgerBloc>(
          create: (_) => InjectionContainer.studentLedgerBloc,
        ),
        BlocProvider<SelectedStudentCubit>(
          create: (_) => InjectionContainer.selectedStudentCubit,
        ),
        BlocProvider<SupportTicketListBloc>(
          create: (_) => InjectionContainer.supportTicketListBloc,
        ),
        BlocProvider<StaffTicketQueueBloc>(
          create: (_) => InjectionContainer.staffTicketQueueBloc,
        ),
        BlocProvider<StaffPendingApprovalsCubit>(
          create: (_) => InjectionContainer.staffPendingApprovalsCubit,
        ),
        BlocProvider<StaffAnnouncementsCubit>(
          create: (_) => InjectionContainer.staffAnnouncementsCubit,
        ),
        BlocProvider<ChatBloc>(
          create: (_) => InjectionContainer.chatBloc,
        ),
        BlocProvider<NoticeBoardBloc>(
          create: (_) => InjectionContainer.noticeBoardBloc,
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => InjectionContainer.profileBloc,
        ),
        BlocProvider<AttendanceHistoryBloc>(
          create: (_) => InjectionContainer.attendanceHistoryBloc,
        ),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'TAFS',
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
