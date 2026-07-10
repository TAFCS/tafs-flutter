import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final bool isStaff;
  final String? initialEmail;
  final bool fromLoggedInSession;

  const ForgotPasswordPage({
    super.key,
    required this.isStaff,
    this.initialEmail,
    this.fromLoggedInSession = false,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.initialEmail?.trim();
    if (initialEmail != null && initialEmail.isNotEmpty) {
      _emailController.text = initialEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthForgotPasswordRequested(
            email: _emailController.text.trim(),
            isStaff: widget.isStaff,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is ForgotPasswordSent || current is ForgotPasswordFailed,
      listener: (context, state) {
        if (state is ForgotPasswordSent) {
          final email = _emailController.text.trim();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordPage(
                email: email,
                isStaff: widget.isStaff,
                fromLoggedInSession: widget.fromLoggedInSession,
              ),
            ),
          );
        } else if (state is ForgotPasswordFailed) {
          showAppSnackBar(context, state.message, type: AppSnackBarType.error);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is ForgotPasswordSending;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Reset Password'),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset('assets/logo.png', height: 80),
                        const SizedBox(height: 32),
                        Text(
                          'Reset Your Password',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.fromLoggedInSession
                              ? 'We\'ll send a verification code to your registered email.'
                              : 'Enter your email address and we\'ll send you a verification code.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        CustomTextField(
                          label: 'Email Address',
                          hint: 'Enter your registered email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: widget.fromLoggedInSession &&
                              (widget.initialEmail?.trim().isNotEmpty ?? false),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: isLoading ? 'Sending...' : 'Send Code',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
