import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/main_dashboard_page.dart';
import '../../auth/domain/entities/student.dart';

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
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            color: AppTheme.surface1,
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                radius: 28,
                backgroundImage: student.profilePictureUrl != null 
                    ? NetworkImage(student.profilePictureUrl!) 
                    : null,
                child: student.profilePictureUrl == null ? Text(
                  student.fullName[0],
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ) : null,
              ),
              title: Text(
                student.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.textMain,
                ),
              ),
              subtitle: Text(
                student.section ?? '',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textMuted,
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainDashboardPage(
                      student: {
                        'cc': student.cc.toString(),
                        'name': student.fullName,
                        'grade': student.section ?? '',
                        'section': '',
                        'gr': 'GR-XXXX',
                        'campus': 'Main Campus'
                      }
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
