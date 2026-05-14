import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import 'student_switcher_sheet.dart';
import '../../../../features/chat/presentation/pages/chat_page.dart';
import '../../../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../../../features/chat/presentation/bloc/chat_state.dart';
import '../../../../features/chat/domain/entities/chat_message.dart';

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
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text('Loading...'),
      );
    }

    return AppBar(
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.navy,
      elevation: 0,
      centerTitle: false,
      actions: [
        if (actions != null) ...actions!,
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            int unreadCount = 0;
            if (state is ChatLoaded) {
              unreadCount = state.unreadCount;
            }
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
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
                  children: [
                    Text(
                      student!.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppTheme.navy),
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
