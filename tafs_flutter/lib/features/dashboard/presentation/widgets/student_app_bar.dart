import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import 'student_switcher_sheet.dart';

class StudentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Student? student;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const StudentAppBar({
    super.key,
    required this.student,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

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
    if (student == null) {
      return AppBar(
        backgroundColor: AppTheme.surface1,
        elevation: 0,
        title: const Text('Loading...'),
      );
    }

    return AppBar(
      backgroundColor: AppTheme.surface1,
      foregroundColor: AppTheme.textMain,
      elevation: 0,
      centerTitle: false,
      actions: actions,
      bottom: bottom,
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
                      student!.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                  ],
                ),
                Text(
                  '${student!.grNumber ?? 'GR-XXXX'} • ${student!.campus ?? 'Main Campus'}',
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
    );
  }
}
