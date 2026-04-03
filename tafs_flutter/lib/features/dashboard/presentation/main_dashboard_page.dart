import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../auth/presentation/login_page.dart';
import 'widgets/app_drawer.dart';
import 'widgets/student_switcher_sheet.dart';
import 'widgets/live_ledger_card.dart';
import 'widgets/communication_feed.dart';
import '../../../../core/widgets/student_profile_card.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import '../../fee_ledger/presentation/bloc/fee_summary_event.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Initial fetch for the already selected student
    final student = context.read<SelectedStudentCubit>().state;
    if (student != null) {
      context.read<FeeSummaryBloc>().add(FeeSummaryLoadRequested(student.cc));
      context.read<FeeLedgerBloc>().add(FeeLedgerLoadRequested(student.cc));
    }
  }

  void _showStudentSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StudentSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
          },
        ),
        BlocListener<SelectedStudentCubit, Student?>(
          listener: (context, student) {
            if (student != null) {
              context
                  .read<FeeSummaryBloc>()
                  .add(FeeSummaryLoadRequested(student.cc));
              context
                  .read<FeeLedgerBloc>()
                  .add(FeeLedgerLoadRequested(student.cc));
            }
          },
        ),
      ],
      child: BlocBuilder<SelectedStudentCubit, Student?>(
        builder: (context, student) {
          if (student == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            drawer: AppDrawer(student: student),
            appBar: AppBar(
              backgroundColor: AppTheme.surface1,
              foregroundColor: AppTheme.textMain,
              elevation: 0,
              centerTitle: false,
              title: GestureDetector(
                onTap: () => _showStudentSwitcher(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down,
                                color: AppTheme.primary),
                          ],
                        ),
                        Text(
                          '${student.grNumber ?? 'GR-XXXX'} • ${student.campus ?? 'Main Campus'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StudentProfileCard(),
                    const SizedBox(height: 16),
                    // Welcome Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primary,
                            Color(0xFF1B436D)
                          ], // Darker Denim
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${student.className} - ${student.section}',
                            style: const TextStyle(
                              color: AppTheme.textOnPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome to TAFS!',
                            style: TextStyle(
                              color: AppTheme.textOnPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Live Ledger
                    LiveLedgerCard(
                      studentCc: student.cc,
                      studentName: student.fullName,
                    ),
                    const SizedBox(height: 32),
                    // Communication Feed
                    const CommunicationFeed(),
                    const SizedBox(height: 16),
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
