import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/fcm_registration_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/theme/app_theme.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verifiedCnic;
  String? _guardianName;
  bool _isSubmitting = false;
  bool _successDialogShown = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _cnicController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _verifyCnic() {
    if (_cnicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a CNIC'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthVerifyCnicRequested(cnic: _cnicController.text.trim()),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthSendSignupOtpRequested(
        cnic: _verifiedCnic!,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        guardianName: _guardianName ?? 'Guardian',
      ),
    );
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(
      AuthSendSignupOtpRequested(
        cnic: _verifiedCnic!,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        guardianName: _guardianName ?? 'Guardian',
      ),
    );
  }

  Future<void> _verifyOtpAndRegister() async {
    if (_otpController.text.trim().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit code'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final fcmToken = await FcmRegistrationService.instance.getToken();
      final deviceType = await FcmRegistrationService.instance.getDeviceType();

      if (!mounted) return;

      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          cnic: _verifiedCnic!,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          guardianName: _guardianName ?? 'Guardian',
          otp: _otpController.text.trim(),
          fcmToken: fcmToken,
          deviceType: deviceType,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetSignup() {
    _cooldownTimer?.cancel();
    context.read<AuthBloc>().add(const AuthSignupResetRequested());
    _cnicController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _otpController.clear();
    _verifiedCnic = null;
    _guardianName = null;
    _isSubmitting = false;
    _successDialogShown = false;
    _resendCooldown = 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is SignupSuccess ||
          current is SignupRegisterFailed ||
          current is SignupCnicInvalid ||
          current is SignupOtpSent ||
          current is SignupOtpFailed,
      listener: (context, state) {
        if (state is SignupSuccess) {
          if (_successDialogShown) return;
          _successDialogShown = true;
          setState(() => _isSubmitting = false);

          final email = _emailController.text.trim();
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Account Created'),
                content: const Text(
                  'Your account has been created successfully. Please log in with your email and password.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pop(context, email);
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              );
            },
          );
        } else if (state is SignupOtpSent) {
          _startResendCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your email'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is SignupOtpFailed) {
          _otpController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state is SignupRegisterFailed) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state is SignupCnicInvalid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isCnicVerifying = state is SignupCnicVerifying;
        final isOtpStep = state is SignupOtpSent ||
            state is SignupRegistering ||
            state is SignupRegisterFailed ||
            state is SignupSuccess;
        final isCnicValid = state is SignupCnicValid ||
            state is SignupOtpSending ||
            state is SignupOtpFailed ||
            isOtpStep;
        final isRegistering = _isSubmitting || state is SignupRegistering;
        final isSendingOtp = state is SignupOtpSending;

        if (state is SignupCnicValid) {
          _verifiedCnic = state.cnic;
          _guardianName = state.guardianName;
        } else if (state is SignupOtpFailed) {
          _verifiedCnic = state.cnic;
          _guardianName = state.guardianName;
        } else if (state is SignupOtpSent) {
          _verifiedCnic = state.cnic;
          _guardianName = state.guardianName;
        } else if (state is SignupRegisterFailed) {
          _verifiedCnic = state.cnic;
          _guardianName = state.guardianName;
        }

        return PopScope(
          canPop: !isCnicValid,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              context.read<AuthBloc>().add(
                const AuthSignupExitToLoginRequested(),
              );
            } else if (isCnicValid) {
              _resetSignup();
            }
          },
          child: Scaffold(
            body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/logo.png', height: 80),
                    const SizedBox(height: 32),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to access your student accounts',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (!isCnicValid) ...[
                      // CNIC Verification Step
                      Text(
                        'Step 1: Verify Your CNIC',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'CNIC',
                        hint: 'XXXXX-XXXXXXX-X',
                        controller: _cnicController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          _CnicFormatter(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: isCnicVerifying ? 'Verifying...' : 'Verify CNIC',
                        isLoading: isCnicVerifying,
                        onPressed: isCnicVerifying ? null : _verifyCnic,
                      ),
                    ] else if (!isOtpStep) ...[
                      // Step 2: Email/Password
                      Text(
                        'Step 2: Set Up Your Account',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.navy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guardian: $_guardianName',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CNIC: $_verifiedCnic',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              label: 'Email',
                              hint: 'Enter your email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
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
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Enter a password (min 8 characters)',
                              controller: _passwordController,
                              isPassword: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Confirm Password',
                              hint: 'Confirm your password',
                              controller: _confirmPasswordController,
                              isPassword: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: isSendingOtp
                            ? 'Sending Code...'
                            : 'Continue',
                        isLoading: isSendingOtp,
                        onPressed: isSendingOtp ? null : _sendOtp,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isSendingOtp ? null : _resetSignup,
                        child: const Text('Change CNIC'),
                      ),
                    ] else ...[
                      // Step 3: OTP Verification
                      Text(
                        'Step 3: Verify Your Email',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A 4-digit code has been sent to ${_emailController.text.trim()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: 'Verification Code',
                        hint: 'Enter 4-digit code',
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: isRegistering
                            ? 'Verifying...'
                            : 'Verify & Create Account',
                        isLoading: isRegistering,
                        onPressed: isRegistering ? null : _verifyOtpAndRegister,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _resendCooldown > 0 || isRegistering
                            ? null
                            : _resendOtp,
                        child: Text(
                          _resendCooldown > 0
                              ? 'Resend code ($_resendCooldown s)'
                              : 'Resend code',
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: isRegistering ? null : _resetSignup,
                        child: const Text('Start over'),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    );
  }
}

class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final buffer = StringBuffer();
    // Keep only digits
    final cleaned = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleaned.length; i++) {
      if (i == 5) {
        buffer.write('-');
      } else if (i == 12) {
        buffer.write('-');
      }
      buffer.write(cleaned[i]);
    }

    final string = buffer.toString();
    
    // Limit to 15 characters (13 digits + 2 hyphens)
    if (string.length > 15) {
      return oldValue;
    }

    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
