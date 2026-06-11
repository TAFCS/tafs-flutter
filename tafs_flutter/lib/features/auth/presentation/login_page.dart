import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/fcm_registration_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/theme/app_theme.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'signup_page.dart';

enum _LoginMode { parent, staff }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginMode _mode = _LoginMode.parent;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_loginError != null) setState(() => _loginError = null);
  }

  void _setMode(_LoginMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _loginError = null;
      _usernameController.clear();
    });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mode == _LoginMode.staff) {
      context.read<AuthBloc>().add(
            AuthStaffLoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
      return;
    }

    final fcmToken = await FcmRegistrationService.instance.getToken();
    final deviceType = await FcmRegistrationService.instance.getDeviceType();
    if (!mounted) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            fcmToken: fcmToken,
            deviceType: deviceType,
          ),
        );
  }

  @override
  void dispose() {
    _usernameController.dispose();
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
        final isStaff = _mode == _LoginMode.staff;

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final vertPad = (h * 0.06).clamp(16.0, 40.0);
                final sectionGap = (h * 0.05).clamp(16.0, 40.0);
                final fieldGap = (h * 0.035).clamp(12.0, 24.0);
                final logoHeight = (h * 0.12).clamp(56.0, 88.0);

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
                            SizedBox(height: sectionGap * 0.5),
                            Center(
                              child: Image.asset(
                                'assets/logo.png',
                                height: logoHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            Text(
                              'Sign in to TAFS',
                              style: Theme.of(context).textTheme.displayMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.space2),
                            Text(
                              isStaff
                                  ? 'Staff portal — support tickets and school operations.'
                                  : 'Parent portal — fees, updates, and school queries.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.blue300,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: sectionGap),
                            _LoginModeSwitcher(
                              mode: _mode,
                              onChanged: _setMode,
                            ),
                            const SizedBox(height: AppTheme.space5),
                            CustomTextField(
                              label: isStaff ? 'Username' : 'Email Address',
                              hint: isStaff
                                  ? 'e.g. general.respondent'
                                  : 'e.g. parent@example.com',
                              controller: _usernameController,
                              keyboardType: isStaff
                                  ? TextInputType.text
                                  : TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return isStaff
                                      ? 'Please enter your username'
                                      : 'Please enter your email address';
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
                                  border: Border.all(
                                    color: AppTheme.danger.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppTheme.danger,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppTheme.space2),
                                    Expanded(
                                      child: Text(
                                        _loginError!,
                                        style: const TextStyle(
                                          color: AppTheme.danger,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(height: sectionGap),
                            CustomButton(
                              text: isStaff ? 'Sign in as Staff' : 'Sign in as Parent',
                              isLoading: isLoading,
                              onPressed: _login,
                            ),
                            if (!isStaff) ...[
                              const SizedBox(height: AppTheme.space4),
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
                                    onPressed: () async {
                                      final email = await Navigator.push<String>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SignupPage(),
                                        ),
                                      );
                                      if (email != null && mounted) {
                                        _usernameController.text = email;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Account created. Please log in.',
                                            ),
                                          ),
                                        );
                                      }
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
                            ],
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

/// Compact role picker sitting above the credential fields.
class _LoginModeSwitcher extends StatelessWidget {
  final _LoginMode mode;
  final ValueChanged<_LoginMode> onChanged;

  const _LoginModeSwitcher({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.blue100.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Parent',
              icon: Icons.family_restroom_outlined,
              selected: mode == _LoginMode.parent,
              onTap: () => onChanged(_LoginMode.parent),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Staff',
              icon: Icons.badge_outlined,
              selected: mode == _LoginMode.staff,
              onTap: () => onChanged(_LoginMode.staff),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppTheme.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.navy.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppTheme.white : AppTheme.blue300,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.white : AppTheme.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
