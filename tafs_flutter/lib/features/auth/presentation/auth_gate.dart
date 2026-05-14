import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../auth/presentation/login_page.dart';
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
      listener: (context, state) {
        // If the user logs out from deep within the app, pop all pushed routes
        // so we return to this root widget (which will now render LoginPage).
        if (state is AuthUnauthenticated) {
          Navigator.popUntil(context, (route) => route.isFirst);
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

          if (authState is AuthUnauthenticated) {
            return const LoginPage();
          }

          // AuthInitial / AuthLoading — branded splash
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
