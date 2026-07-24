import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_cached_network_image.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';

class StudentSelectionPage extends StatelessWidget {
  final List<Student> students;

  const StudentSelectionPage({super.key, required this.students});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppTheme.space6, AppTheme.space12, AppTheme.space6, AppTheme.space8),
            decoration: const BoxDecoration(
              gradient: AppTheme.navyGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Student Selection',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  'Please select a profile to continue to the dashboard.',
                  style: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.space6),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.space4),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.blue100),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: InkWell(
                    onTap: () => context.read<SelectedStudentCubit>().select(student),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space5),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.blue100, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.navy.withValues(alpha: 0.05),
                              backgroundImage: appCachedNetworkImageProvider(student.photographUrl),
                              child: student.photographUrl == null
                                  ? Text(
                                      student.fullName[0],
                                      style: const TextStyle(
                                        color: AppTheme.navy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.fullName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${student.className ?? "N/A"} • Section ${student.section ?? "N/A"}',
                                  style: const TextStyle(
                                    color: AppTheme.blue300,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.school_rounded, size: 12, color: AppTheme.blue200),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        student.campus ?? 'No Campus Assigned',
                                        style: const TextStyle(color: AppTheme.blue200, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.navy.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.navy),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
