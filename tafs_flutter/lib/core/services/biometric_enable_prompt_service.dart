import 'package:flutter/material.dart';

import '../widgets/app_dialog_actions.dart';
import '../widgets/app_snackbar.dart';
import 'biometric_auth_service.dart';
import 'saved_credentials_service.dart';

/// Coordinates the post-login "Enable Face ID / biometrics?" prompt.
class BiometricEnablePromptService {
  BiometricEnablePromptService({
    required BiometricAuthService biometricAuth,
    required SavedCredentialsService savedCredentials,
  })  : _biometricAuth = biometricAuth,
        _savedCredentials = savedCredentials;

  final BiometricAuthService _biometricAuth;
  final SavedCredentialsService _savedCredentials;

  String? _pendingUsername;
  String? _pendingPassword;
  bool _pendingIsStaff = false;
  bool _skipNextPrompt = false;

  void stagePasswordLogin({
    required String username,
    required String password,
    required bool isStaff,
  }) {
    _pendingUsername = username;
    _pendingPassword = password;
    _pendingIsStaff = isStaff;
    _skipNextPrompt = false;
  }

  void skipNextPrompt() {
    _skipNextPrompt = true;
    _clearPending();
  }

  void _clearPending() {
    _pendingUsername = null;
    _pendingPassword = null;
  }

  Future<void> handleLoginSuccess(BuildContext context) async {
    if (_skipNextPrompt) {
      _skipNextPrompt = false;
      return;
    }

    final username = _pendingUsername;
    final password = _pendingPassword;
    final isStaff = _pendingIsStaff;
    _clearPending();

    if (username == null || password == null) return;
    if (!await _biometricAuth.canUseBiometrics()) return;
    if (await _savedCredentials.hasSavedCredentials(isStaff: isStaff)) {
      await _savedCredentials.save(
        isStaff: isStaff,
        username: username,
        password: password,
      );
      return;
    }
    if (await _savedCredentials.hasDeclinedBiometricPrompt(isStaff: isStaff)) {
      return;
    }
    if (!context.mounted) return;

    final label = await _biometricAuth.getBiometricLabel();
    if (!context.mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Enable $label?'),
        content: Text(
          'Sign in faster next time using $label instead of typing your password.',
        ),
        actions: [
          AppDialogActions.secondary(
            dialogContext,
            label: 'Not now',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogActions.primary(
            dialogContext,
            label: 'Enable $label',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (enable == true) {
      final authenticated = await _biometricAuth.authenticate();
      if (!context.mounted) return;
      if (authenticated) {
        await _savedCredentials.save(
          isStaff: isStaff,
          username: username,
          password: password,
        );
        if (!context.mounted) return;
        showAppSnackBar(context, '$label sign-in enabled', type: AppSnackBarType.success);
      } else {
        showAppSnackBar(
          context,
          '$label setup was not completed',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    await _savedCredentials.setDeclinedBiometricPrompt(isStaff: isStaff);
  }
}
