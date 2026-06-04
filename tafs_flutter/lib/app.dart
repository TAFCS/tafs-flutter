import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/selected_student_cubit.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/bloc/chat_event.dart';
import 'features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import 'features/fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import 'features/notice_board/presentation/bloc/notice_board_bloc.dart';
import 'features/notice_board/presentation/bloc/notice_board_event.dart';
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
        BlocProvider<SelectedStudentCubit>(
          create: (_) => InjectionContainer.selectedStudentCubit,
        ),
        BlocProvider<ChatBloc>(
          create: (_) => InjectionContainer.chatBloc,
        ),
        BlocProvider<NoticeBoardBloc>(
          create: (_) => InjectionContainer.noticeBoardBloc,
        ),
      ],
      child: MaterialApp(
        title: 'TAFS Parent Portal',
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
