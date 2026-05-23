import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/theme/app_theme.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      // FCM and Platform.isAndroid are mobile-only — both crash on web.
      String? fcmToken;
      String? deviceType;

      if (!kIsWeb) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
          deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';
        } catch (e) {
          print('Error getting FCM token on login: $e');
        }
      }

      if (!mounted) return;

      context.read<AuthBloc>().add(
        AuthLoginRequested(
          username: _emailController.text.trim(),
          password: _passwordController.text,
          fcmToken: fcmToken,
          deviceType: deviceType,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adaptive spacing: tighter on small screens (< 680px), normal otherwise.
                final h = constraints.maxHeight;
                final vertPad = (h * 0.06).clamp(16.0, 40.0);
                final sectionGap = (h * 0.06).clamp(16.0, 48.0);
                final fieldGap = (h * 0.035).clamp(12.0, 24.0);
                final logoHeight = (h * 0.14).clamp(60.0, 100.0);

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: vertPad,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: sectionGap),
                            // Logo
                            Center(
                              child: Image.asset(
                                'assets/logo.png',
                                height: logoHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            // Welcome text
                            Text(
                              'Welcome Back',
                              style: Theme.of(context).textTheme.displayMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.space2),
                            Text(
                              'Log in to your parent portal to manage fees and stay updated.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.blue300,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: sectionGap),
                            // Form fields
                            CustomTextField(
                              label: 'Email Address',
                              hint: 'e.g. parent@example.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: fieldGap),
                            CustomTextField(
                              label: 'Password',
                              hint: '••••••••',
                              isPassword: true,
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: sectionGap),
                            // Login button
                            CustomButton(
                              text: 'Log In',
                              isLoading: isLoading,
                              onPressed: _login,
                            ),
                            const SizedBox(height: AppTheme.space4),
                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.blue300,
                                      ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignupPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.navy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: sectionGap),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

