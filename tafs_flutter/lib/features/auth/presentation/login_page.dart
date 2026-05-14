import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          username: _emailController.text.trim(),
          password: _passwordController.text,
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
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space8,
                          vertical: AppTheme.space10,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(flex: 2),
                              // Logo with subtle shadow
                              Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: AppTheme.shadowSm,
                                  ),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    height: 100,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.space12),
                              // Welcome Text
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
                              const SizedBox(height: AppTheme.space12),
                              // Form Fields
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
                              const SizedBox(height: AppTheme.space6),
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
                              const SizedBox(height: AppTheme.space10),
                              // Login Button
                              CustomButton(
                                text: 'Log In',
                                isLoading: isLoading,
                                onPressed: _login,
                              ),
                              const SizedBox(height: AppTheme.space6),
                              // Sign Up Link
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
                              const Spacer(flex: 3),
                            ],
                          ),
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

