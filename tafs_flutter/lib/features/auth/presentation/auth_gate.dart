import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'dart:async';

import '../../../core/services/fcm_registration_service.dart';
import '../../../core/session/authenticated_session.dart';
import '../../../core/session/logout_lock.dart';
import '../../../core/session/session_reset.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/full_screen_loader.dart';
import '../../../core/widgets/notification_permission_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';
import '../../auth/domain/entities/parent.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../auth/presentation/login_page.dart';
import '../../dashboard/presentation/main_shell_page.dart';
import '../../profile/presentation/student_selection_page.dart';
import '../../employee_portal/presentation/pages/employee_main_shell.dart';

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

  showNotificationPermissionBanner(context);
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

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
    } else if (currentState is AuthAuthenticatedStaff) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthBloc>().add(const AuthStaffRefreshRequested());
        unawaited(_showNotificationPermissionHintIfNeeded(context));
      });
    }
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (results.every((r) => r == ConnectivityResult.none)) {
        messenger.showMaterialBanner(
          MaterialBanner(
            backgroundColor: Colors.red.shade50,
            leading: Icon(Icons.wifi_off_rounded, color: Colors.red.shade700),
            content: Text(
              'No internet connection',
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => messenger.hideCurrentMaterialBanner(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      } else {
        messenger.hideCurrentMaterialBanner();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoggingOutNotifier,
      builder: (context, loggingOut, child) {
        return BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) =>
              (current is AuthLoading) != (previous is AuthLoading),
          builder: (context, authState) {
            final signingIn = !loggingOut && authState is AuthLoading;
            return Stack(
              children: [
                child!,
                if (loggingOut) const FullScreenLoader(message: 'Logging out...'),
                if (signingIn) const FullScreenLoader(message: 'Signing in...'),
              ],
            );
          },
        );
      },
      child: MultiBlocListener(
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
            isLoggingOutNotifier.value = false;
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthAccountDeletionRequested,
          listener: (context, state) {
            if (state is! AuthAccountDeletionRequested) return;
            showAppSnackBar(
              context,
              'Account deletion request submitted. An admin will review it shortly.',
              type: AppSnackBarType.success,
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
              unawaited(
                InjectionContainer.biometricEnablePromptService
                    .handleLoginSuccess(context),
              );
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthAuthenticatedStaff &&
              previous is AuthLoading,
          listener: (context, state) {
            unawaited(_showNotificationPermissionHintIfNeeded(context));
            unawaited(
              InjectionContainer.biometricEnablePromptService
                  .handleLoginSuccess(context),
            );
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
            return EmployeeMainShell(staff: authState.staff);
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

          // Splash only while cold-start session check is in flight.
          // All other unauthenticated flows keep LoginPage as the home route
          // so pops never reveal a loading screen behind pushed routes.
          if (authState is AuthInitial) {
            return Scaffold(
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.navyGradient,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.white,
                  ),
                ),
              ),
            );
          }

          return const LoginPage();
        },
      ),
      ),
    );
  }
}
