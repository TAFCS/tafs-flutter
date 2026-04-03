import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';

class StudentSwitcherSheet extends StatelessWidget {
  const StudentSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final siblings = authState.parent.students;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Switch Student',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...siblings.map((student) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              color: AppTheme.surface1,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  backgroundImage: student.photographUrl != null
                      ? NetworkImage(student.photographUrl!)
                      : null,
                  child: student.photographUrl == null
                      ? Text(
                          student.fullName[0],
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  student.fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                subtitle: Text(
                  '${student.className} - ${student.section}\n${student.grNumber} • ${student.campus}',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                isThreeLine: true,
                onTap: () {
                  context.read<SelectedStudentCubit>().select(student);
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
