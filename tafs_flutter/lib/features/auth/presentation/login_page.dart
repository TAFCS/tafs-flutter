import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/services/fcm_registration_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../injection_container.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'widgets/biometric_sign_in_button.dart';

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
  bool _biometricsAvailable = false;
  bool _hasSavedCredentials = false;
  bool _biometricLoading = false;
  String _biometricLabel = 'Biometrics';

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final isStaff = _mode == _LoginMode.staff;
    final available =
        await InjectionContainer.biometricAuthService.canUseBiometrics();
    final hasSaved = available &&
        await InjectionContainer.savedCredentialsService
            .hasSavedCredentials(isStaff: isStaff);
    final label = available
        ? await InjectionContainer.biometricAuthService.getBiometricLabel()
        : 'Biometrics';

    if (!mounted) return;

    setState(() {
      _biometricsAvailable = available;
      _hasSavedCredentials = hasSaved;
      _biometricLabel = label;
    });

    if (hasSaved) {
      final creds = await InjectionContainer.savedCredentialsService
          .load(isStaff: isStaff);
      if (creds != null && mounted) {
        _usernameController.text = creds.username;
      }
    }
  }

  void _clearError() {
    if (_loginError != null) setState(() => _loginError = null);
  }

  void _switchMode(_LoginMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _loginError = null;
      _usernameController.clear();
      _passwordController.clear();
    });
    _loadBiometricState();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final isStaff = _mode == _LoginMode.staff;

    InjectionContainer.biometricEnablePromptService.stagePasswordLogin(
      username: username,
      password: password,
      isStaff: isStaff,
    );

    if (isStaff) {
      context.read<AuthBloc>().add(
            AuthStaffLoginRequested(
              username: username,
              password: password,
            ),
          );
      return;
    }

    final fcmToken = await FcmRegistrationService.instance.getToken();
    final deviceType = await FcmRegistrationService.instance.getDeviceType();
    if (!mounted) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            username: username,
            password: password,
            fcmToken: fcmToken,
            deviceType: deviceType,
          ),
        );
  }

  Future<void> _biometricLogin() async {
    if (_biometricLoading) return;

    setState(() => _biometricLoading = true);
    InjectionContainer.biometricEnablePromptService.skipNextPrompt();

    final authResult =
        await InjectionContainer.biometricAuthService.authenticateDetailed();
    if (!authResult.success) {
      if (mounted) {
        setState(() => _biometricLoading = false);
        showAppSnackBar(
          context,
          InjectionContainer.biometricAuthService.failureMessage(
            label: _biometricLabel,
            failure: authResult.failure ?? BiometricAuthFailure.unknown,
          ),
        );
      }
      return;
    }

    final isStaff = _mode == _LoginMode.staff;
    final creds = await InjectionContainer.savedCredentialsService
        .load(isStaff: isStaff);
    if (creds == null) {
      if (mounted) {
        setState(() {
          _biometricLoading = false;
          _hasSavedCredentials = false;
        });
        showAppSnackBar(
          context,
          'Saved credentials not found. Please sign in with your password.',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    if (!mounted) return;

    if (isStaff) {
      context.read<AuthBloc>().add(
            AuthStaffLoginRequested(
              username: creds.username,
              password: creds.password,
            ),
          );
      return;
    }

    final fcmToken = await FcmRegistrationService.instance.getToken();
    final deviceType = await FcmRegistrationService.instance.getDeviceType();
    if (!mounted) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            username: creds.username,
            password: creds.password,
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
      listenWhen: (_, current) => current is AuthError || current is AuthLoading,
      listener: (context, state) {
        if (state is AuthError) {
          setState(() {
            _loginError = state.message;
            _biometricLoading = false;
          });
        } else if (state is AuthLoading) {
          setState(() => _loginError = null);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final isStaff = _mode == _LoginMode.staff;
        final showBiometricButton =
            _biometricsAvailable && _hasSavedCredentials;

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final vertPad = (h * 0.05).clamp(12.0, 32.0);
                final sectionGap = (h * (showBiometricButton ? 0.035 : 0.05))
                    .clamp(12.0, showBiometricButton ? 28.0 : 40.0);
                final fieldGap = (h * 0.03).clamp(10.0, 20.0);
                final logoHeight = (h * (showBiometricButton ? 0.09 : 0.12))
                    .clamp(48.0, showBiometricButton ? 72.0 : 88.0);

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
                            SizedBox(height: sectionGap),
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
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(
                                    color:
                                        AppTheme.danger.withValues(alpha: 0.3),
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ForgotPasswordPage(
                                        isStaff: isStaff,
                                      ),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.navy,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            CustomButton(
                              text: 'Sign in',
                              isLoading: isLoading,
                              onPressed: isLoading || _biometricLoading
                                  ? null
                                  : _login,
                            ),
                            if (showBiometricButton) ...[
                              SizedBox(height: AppTheme.space3),
                              Center(
                                child: BiometricSignInButton(
                                  label: _biometricLabel,
                                  isLoading: _biometricLoading,
                                  onPressed: isLoading || _biometricLoading
                                      ? null
                                      : _biometricLogin,
                                ),
                              ),
                            ],
                            if (!isStaff) ...[
                              const SizedBox(height: AppTheme.space4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.blue300,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final email =
                                          await Navigator.push<String>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignupPage(),
                                        ),
                                      );
                                      if (!context.mounted) return;
                                      if (email != null) {
                                        _usernameController.text = email;
                                        showAppSnackBar(
                                          context,
                                          'Account created. Please log in.',
                                          type: AppSnackBarType.success,
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.navy,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: sectionGap),
                            GestureDetector(
                              onTap: () => _switchMode(
                                isStaff ? _LoginMode.parent : _LoginMode.staff,
                              ),
                              child: Text(
                                isStaff
                                    ? '← Back to parent sign in'
                                    : 'Are you a TAFS employee? Sign in here',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            SizedBox(height: sectionGap * 0.5),
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
