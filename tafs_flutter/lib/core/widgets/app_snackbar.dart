import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppSnackBarType { info, success, error }

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
}) {
  final backgroundColor = switch (type) {
    AppSnackBarType.success => AppTheme.success,
    AppSnackBarType.error => AppTheme.danger,
    AppSnackBarType.info => null,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
    ),
  );
}
