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
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.blue100),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.blue100, width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.blue100.withValues(alpha: 0.3),
                  backgroundImage: student.photographUrl != null
                      ? NetworkImage(student.photographUrl!)
                      : null,
                  child: student.photographUrl == null
                      ? Text(
                          student.fullName[0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      '${student.grNumber ?? 'N/A'} • ${student.className ?? ''} - ${student.section ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.blue300,
                          ),
                    ),
                    Text(
                      student.campus ?? 'Main Campus',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.blue200,
                          ),
                    ),
                  ],
                ),
              ),
              if (showEditButton)
                const Icon(Icons.edit_outlined,
                    color: AppTheme.navy, size: 20),
            ],
          ),
        );
      },
    );
  }
}

