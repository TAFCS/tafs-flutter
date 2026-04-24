import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/main_dashboard_page.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';

class StudentSelectionPage extends StatelessWidget {
  final List<Student> students;

  const StudentSelectionPage({super.key, required this.students});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('Select Student'),
          ],
        ),
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: AppTheme.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: AppTheme.shadowL1,
            ),
            child: InkWell(
              onTap: () {
                context.read<SelectedStudentCubit>().select(student);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainDashboardPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Student Photo
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      radius: 32,
                      backgroundImage: student.photographUrl != null
                          ? NetworkImage(student.photographUrl!)
                          : null,
                      child: student.photographUrl == null
                          ? Text(
                              student.fullName.isNotEmpty
                                  ? student.fullName[0]
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Student Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student.className ?? 'Class -'} • ${student.section ?? '-'}',
                            style: const TextStyle(
                              color: AppTheme.textMain,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.campus ?? 'Campus not assigned',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _chip('CC ${student.cc}'),
                              if (student.grNumber != null)
                                _chip('GR ${student.grNumber}'),
                              if (student.academicYear != null)
                                _chip(student.academicYear!),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textMuted,
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

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
