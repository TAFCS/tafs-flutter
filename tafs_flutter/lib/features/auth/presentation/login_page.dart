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
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_loginError != null) setState(() => _loginError = null);
    });
    _passwordController.addListener(() {
      if (_loginError != null) setState(() => _loginError = null);
    });
  }

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
          setState(() => _loginError = state.message);
        } else if (state is AuthLoading) {
          setState(() => _loginError = null);
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
                            if (_loginError != null) ...[
                              const SizedBox(height: AppTheme.space2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space4,
                                  vertical: AppTheme.space3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 16),
                                    const SizedBox(width: AppTheme.space2),
                                    Expanded(
                                      child: Text(
                                        _loginError!,
                                        style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

