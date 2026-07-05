import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppDialogActions {
  static Widget cancel(
    BuildContext context, {
    String label = 'Cancel',
    VoidCallback? onPressed,
  }) {
    return TextButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      child: Text(label),
    );
  }

  static Widget secondary(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  static Widget primary(
    BuildContext context, {
    required String label,
    VoidCallback? onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  static Widget destructive(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
      child: Text(label),
    );
  }
}
