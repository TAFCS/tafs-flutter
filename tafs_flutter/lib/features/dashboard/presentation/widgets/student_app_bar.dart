import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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
      builder: (sheetCtx) => BlocProvider.value(
        value: BlocProvider.of<SelectedStudentCubit>(context),
        child: BlocProvider.value(
          value: BlocProvider.of<AuthBloc>(context),
          child: const StudentSwitcherSheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (student == null) {
      return AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Loading...'),
      );
    }

    return AppBar(
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      actions: [
        if (actions != null) ...actions!,
      ],
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      student!.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.blue300,
                    ),
                  ],
                ),
                Text(
                  '${student!.grNumber ?? 'GR-XXXX'} • ${student!.campus ?? 'Main Campus'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.blue300,
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
