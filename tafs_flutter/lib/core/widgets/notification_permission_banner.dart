import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';

void showNotificationPermissionBanner(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: AppTheme.surface2,
      leading: const Icon(Icons.notifications_off_outlined, color: AppTheme.navy),
      content: const Text(
        'Notifications are turned off. Enable them in Settings to receive school alerts.',
        style: TextStyle(color: AppTheme.navy, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          child: const Text('Dismiss'),
        ),
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
