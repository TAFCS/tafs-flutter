import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../../fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../../fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../../fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import '../../../fee_ledger/presentation/bloc/fee_summary_event.dart';

class StudentSwitcherSheet extends StatelessWidget {
  const StudentSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final siblings = authState.parent.students;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppTheme.space6, AppTheme.space3, AppTheme.space6, AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space5),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.blue100,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Switch Student',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.blue300),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          ...siblings.map((student) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.space3),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.blue100),
                boxShadow: AppTheme.shadowSm,
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space2),
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.blue100, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.blue100.withValues(alpha: 0.3),
                    backgroundImage: student.photographUrl != null
                        ? NetworkImage(student.photographUrl!)
                        : null,
                    child: student.photographUrl == null
                        ? Text(
                            student.fullName[0],
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                title: Text(
                  student.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${student.className} - ${student.section}\n${student.grNumber} • ${student.campus}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.blue300),
                ),
                isThreeLine: true,
                onTap: () {
                  context.read<SelectedStudentCubit>().select(student);
                  context
                      .read<FeeSummaryBloc>()
                      .add(FeeSummaryLoadRequested(student.cc));
                  context
                      .read<FeeLedgerBloc>()
                      .add(LedgerLoadRequested(student.cc));
                  Navigator.pop(context);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

