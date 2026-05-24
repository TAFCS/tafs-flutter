import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FamilyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const FamilyAppBar({super.key, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.navy,
      elevation: 0,
      centerTitle: false,
      actions: actions,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Text(
            'TAFS Connect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}
