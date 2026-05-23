import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/presentation/student_selection_page.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import '../../dashboard/presentation/main_shell_page.dart';
import 'bloc/selected_student_cubit.dart';

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
  final _formKey = GlobalKey<FormState>();

  String? _verifiedCnic;
  String? _guardianName;

  @override
  void dispose() {
    _cnicController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // FCM and Platform.isAndroid are mobile-only — both crash on web.
      String? fcmToken;
      String? deviceType;
      if (!kIsWeb) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
          deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';
        } catch (e) {
          print('Error getting FCM token on register: $e');
        }
      }

      if (!mounted) return;

      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          cnic: _verifiedCnic!,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fcmToken: fcmToken,
          deviceType: deviceType,
        ),
      );
    }
  }

  void _resetSignup() {
    context.read<AuthBloc>().add(const AuthSignupResetRequested());
    _cnicController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _verifiedCnic = null;
    _guardianName = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          final students = state.parent.students;
          if (students.length > 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentSelectionPage(students: students),
              ),
            );
          } else if (students.length == 1) {
            context.read<SelectedStudentCubit>().select(students.first);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainShellPage(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No students linked to this account.'),
              ),
            );
          }
        } else if (state is AuthError) {
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
        final isCnicValid = state is SignupCnicValid;
        final isRegistering = state is SignupRegistering;

        if (isCnicValid) {
          _verifiedCnic = state.cnic;
          _guardianName = state.guardianName;
        }

        return Scaffold(
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
                        hint: 'Enter your CNIC number',
                        controller: _cnicController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: isCnicVerifying ? 'Verifying...' : 'Verify CNIC',
                        isLoading: isCnicVerifying,
                        onPressed: isCnicVerifying ? null : _verifyCnic,
                      ),
                    ] else ...[
                      // Registration Step
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
                        text: isRegistering
                            ? 'Creating Account...'
                            : 'Create Account',
                        isLoading: isRegistering,
                        onPressed: isRegistering ? null : _register,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isRegistering ? null : _resetSignup,
                        child: const Text('Change CNIC'),
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
        );
      },
    );
  }
}
