import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import 'student_switcher_sheet.dart';

/// Toolbar height leaves room for a 2-line student name + subtitle.
const double _kStudentAppBarToolbarHeight = 72;

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
        _kStudentAppBarToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
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
        toolbarHeight: _kStudentAppBarToolbarHeight,
        title: const Text(
          'Loading...',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return AppBar(
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: _kStudentAppBarToolbarHeight,
      titleSpacing: 16,
      actions: [
        if (actions != null) ...actions!,
      ],
      bottom: bottom,
      // Force title to use remaining width between leading & actions
      // so long names wrap instead of cutting off early.
      title: GestureDetector(
        onTap: () => _showStudentSwitcher(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    student!.fullName,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.blue300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
