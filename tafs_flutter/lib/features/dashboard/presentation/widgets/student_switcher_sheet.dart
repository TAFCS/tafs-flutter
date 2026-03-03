import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StudentSwitcherSheet extends StatelessWidget {
  const StudentSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for siblings linked to Family ID
    final siblings = [
      {'name': 'Ahmad Ali', 'grade': 'Grade 5', 'section': 'A', 'campus': 'Main Campus', 'gr': 'GR-1209'},
      {'name': 'Fatima Ali', 'grade': 'Grade 3', 'section': 'B', 'campus': 'Main Campus', 'gr': 'GR-1450'},
    ];

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    student['name']![0],
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  student['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                subtitle: Text(
                  '${student['grade']} - ${student['section']}\n${student['gr']} • ${student['campus']}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                isThreeLine: true,
                onTap: () {
                  // Dispatch SwitchStudentContext event to BLoC here in the future
                  Navigator.pop(context, student);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
