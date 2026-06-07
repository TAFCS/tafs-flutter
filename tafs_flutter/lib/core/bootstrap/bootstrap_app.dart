import 'dart:async';

import 'package:flutter/material.dart';

import '../error/api_error_mapper.dart';
import '../../injection_container.dart';
import '../../app.dart';
import '../theme/app_theme.dart';
import 'app_bootstrap.dart';

/// Shows UI immediately, then completes env/storage/DI without blocking the native splash.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  _BootstrapPhase _phase = _BootstrapPhase.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await AppBootstrap.prepareCore();
      InjectionContainer.init();
      if (!mounted) return;
      setState(() => _phase = _BootstrapPhase.ready);

      // After first frame: Firebase/push (must not block initial paint).
      unawaited(AppBootstrap.initFirebaseAndNotifications());
    } catch (e, st) {
      debugPrint('Bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _BootstrapPhase.error;
        _errorMessage = ApiErrorMapper.fromObject(
          e,
          fallback: 'Unable to start the app. Please try again.',
        );
      });
    }
  }

  void _retry() {
    setState(() {
      _phase = _BootstrapPhase.loading;
      _errorMessage = null;
    });
    unawaited(_run());
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _BootstrapPhase.ready:
        return const MyApp();
      case _BootstrapPhase.loading:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(gradient: AppTheme.navyGradient),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.white,
                ),
              ),
            ),
          ),
        );
      case _BootstrapPhase.error:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not start the app',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

enum _BootstrapPhase { loading, ready, error }
