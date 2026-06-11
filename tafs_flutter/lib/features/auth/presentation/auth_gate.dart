import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:async';

import '../../../core/services/fcm_registration_service.dart';
import '../../../core/session/authenticated_session.dart';
import '../../../core/session/session_reset.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/parent.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../auth/presentation/login_page.dart';
import '../../dashboard/presentation/main_shell_page.dart';
import '../../profile/presentation/student_selection_page.dart';
import '../../support_tickets/staff/presentation/pages/staff_support_tickets_shell.dart';

/// AuthGate is the app root widget.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

Future<void> _showNotificationPermissionHintIfNeeded(BuildContext context) async {
  final granted =
      await FcmRegistrationService.instance.isNotificationPermissionGranted();
  if (granted || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Enable notifications in Settings to receive school alerts.',
      ),
      duration: Duration(seconds: 5),
    ),
  );
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    final currentState = context.read<AuthBloc>().state;
    if (currentState is AuthInitial) {
      context.read<AuthBloc>().add(AuthCheckRequested());
    } else if (currentState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        startAuthenticatedSession(
          context,
          students: currentState.parent.students,
        );
        unawaited(_showNotificationPermissionHintIfNeeded(context));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            if (current is! AuthUnauthenticated) return false;
            return previous is AuthAuthenticated ||
                previous is AuthAuthenticatedStaff ||
                previous is AuthLoading ||
                previous is AuthProfileRefreshFailed ||
                previous is AuthAccountDeletionRequested;
          },
          listener: (context, state) {
            Navigator.popUntil(context, (route) => route.isFirst);
            resetSessionState(context);
            resetStaffSessionState(context);
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthAccountDeletionRequested,
          listener: (context, state) {
            if (state is! AuthAccountDeletionRequested) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Account deletion request submitted. An admin will review it shortly.',
                ),
              ),
            );
            context.read<AuthBloc>().add(
                  AuthAccountDeletionRequestedAcknowledged(state.parent),
                );
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthAuthenticated &&
              previous is! AuthAuthenticated &&
              previous is! AuthProfileRefreshFailed,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              startAuthenticatedSession(
                context,
                students: state.parent.students,
              );
              unawaited(_showNotificationPermissionHintIfNeeded(context));
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            if (current is! AuthAuthenticated || previous is! AuthAuthenticated) {
              return false;
            }
            return previous.parent.students != current.parent.students;
          },
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              syncSelectedStudent(context, state.parent.students);
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticatedStaff) {
            return StaffSupportTicketsShell(staff: authState.staff);
          }

          final Parent? sessionParent = switch (authState) {
            AuthAuthenticated(:final parent) => parent,
            AuthProfileRefreshFailed(:final parent) => parent,
            AuthAccountDeletionRequested(:final parent) => parent,
            _ => null,
          };

          if (sessionParent != null) {
            final students = sessionParent.students;

            return BlocBuilder<SelectedStudentCubit, Student?>(
              builder: (context, selectedStudent) {
                final cubit = context.read<SelectedStudentCubit>();

                if (selectedStudent == null && students.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (cubit.state == null && students.isNotEmpty) {
                      cubit.select(students.first);
                    }
                  });
                }

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
