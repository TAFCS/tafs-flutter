import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/student.dart';
import '../../features/auth/presentation/bloc/selected_student_cubit.dart';
import '../theme/app_theme.dart';

class StudentProfileCard extends StatelessWidget {
  final bool showEditButton;

  const StudentProfileCard({super.key, this.showEditButton = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectedStudentCubit, Student?>(
      builder: (context, student) {
        if (student == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: student.photographUrl != null
                    ? NetworkImage(student.photographUrl!)
                    : null,
                child: student.photographUrl == null
                    ? Text(
                        student.fullName[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.grNumber ?? 'N/A'} • ${student.className ?? ''} - ${student.section ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      student.campus ?? 'Main Campus',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (showEditButton)
                const Icon(Icons.edit_outlined,
                    color: AppTheme.primary, size: 20),
            ],
          ),
        );
      },
    );
  }
}
