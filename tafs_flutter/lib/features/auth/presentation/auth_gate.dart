import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../auth/presentation/login_page.dart';
import '../../chat/presentation/bloc/chat_bloc.dart';
import '../../chat/presentation/bloc/chat_event.dart';
import '../../dashboard/presentation/main_shell_page.dart';
import '../../profile/presentation/student_selection_page.dart';

/// AuthGate is the app root widget.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    final currentState = context.read<AuthBloc>().state;
    if (currentState is AuthInitial) {
      context.read<AuthBloc>().add(AuthCheckRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Only react to actual session transitions: login or logout.
      // Token refresh and profile updates re-emit AuthAuthenticated without
      // changing the session, so we must NOT restart the chat for those.
      listenWhen: (previous, current) {
        // Only clear the nav stack on real logout — not signup CNIC reset / exit.
        if (current is AuthUnauthenticated) {
          return previous is AuthAuthenticated;
        }
        return current is AuthAuthenticated && previous is! AuthAuthenticated;
      },
      listener: (context, state) {
        // If the user logs out from deep within the app, pop all pushed routes
        // so we return to this root widget (which will now render LoginPage).
        if (state is AuthUnauthenticated) {
          Navigator.popUntil(context, (route) => route.isFirst);
          context.read<ChatBloc>().add(ChatSessionStopRequested());
        } else if (state is AuthAuthenticated) {
          context.read<ChatBloc>().add(ChatSessionStartRequested());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final students = authState.parent.students;

            return BlocBuilder<SelectedStudentCubit, Student?>(
              builder: (context, selectedStudent) {
                final cubit = context.read<SelectedStudentCubit>();

                // Select first student post-frame if none selected
                if (selectedStudent == null && students.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (cubit.state == null && students.isNotEmpty) {
                      cubit.select(students.first);
                    }
                  });
                }

                // If multiple students and none picked yet, go to selection page
                if (students.length > 1 && selectedStudent == null) {
                  return StudentSelectionPage(students: students);
                }

                return const MainShellPage();
              },
            );
          }

          if (authState is AuthUnauthenticated ||
              authState is AuthError ||
              authState is AuthLoading ||
              authState is SignupInitial ||
              authState is SignupCnicVerifying ||
              authState is SignupCnicValid ||
              authState is SignupCnicInvalid ||
              authState is SignupRegistering ||
              authState is SignupRegisterFailed ||
              authState is SignupSuccess) {
            return const LoginPage();
          }

          // AuthInitial — branded splash while session check runs
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.navyGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image.asset('assets/logo.png', height: 80, color: Colors.white),
                    SizedBox(height: 24),
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
