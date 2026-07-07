import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../injection_container.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class ChangePasswordPage extends StatefulWidget {
  final bool isStaff;

  const ChangePasswordPage({super.key, required this.isStaff});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final current = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPassword != confirm) {
      showAppSnackBar(
        context,
        'Passwords do not match',
        type: AppSnackBarType.error,
      );
      return;
    }

    if (current == newPassword) {
      showAppSnackBar(
        context,
        'New password must be different from current password',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    context.read<AuthBloc>().add(
          AuthChangePasswordRequested(
            currentPassword: current,
            newPassword: newPassword,
            isStaff: widget.isStaff,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) =>
          current is ChangePasswordSuccess || current is ChangePasswordFailed,
      listener: (context, state) async {
        if (!mounted) return;

        if (state is ChangePasswordSuccess) {
          await InjectionContainer.savedCredentialsService.clear(
            isStaff: widget.isStaff,
          );
          if (!context.mounted) return;
          showAppSnackBar(
            context,
            'Password changed successfully',
            type: AppSnackBarType.success,
          );
          Navigator.of(context).pop();
        } else if (state is ChangePasswordFailed) {
          setState(() => _isSubmitting = false);
          showAppSnackBar(context, state.message, type: AppSnackBarType.error);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.white,
        appBar: AppBar(
          backgroundColor: AppTheme.white,
          foregroundColor: AppTheme.navy,
          elevation: 0,
          title: const Text(
            'Change password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space5),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your current password, then choose a new one.',
                    style: TextStyle(
                      color: AppTheme.blue300,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space6),
                  CustomTextField(
                    label: 'Current password',
                    hint: '••••••••',
                    isPassword: true,
                    controller: _currentPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space4),
                  CustomTextField(
                    label: 'New password',
                    hint: 'At least 8 characters',
                    isPassword: true,
                    controller: _newPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space4),
                  CustomTextField(
                    label: 'Confirm new password',
                    hint: 'Re-enter your new password',
                    isPassword: true,
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space8),
                  CustomButton(
                    text: 'Save password',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
