import 'dart:async';

import 'package:flutter/material.dart';

import '../error/api_error_mapper.dart';
import '../../injection_container.dart';
import '../../app.dart';
import '../theme/app_theme.dart';
import 'app_bootstrap.dart';
import '../app_status/app_status_screens.dart';
import '../app_status/app_status_service.dart';

/// Shows UI immediately, then completes env/storage/DI without blocking the native splash.
class BootstrapApp extends StatefulWidget {
  /// Optional override for tests.
  final AppStatusService? appStatusService;

  const BootstrapApp({super.key, this.appStatusService});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> with WidgetsBindingObserver {
  _BootstrapPhase _phase = _BootstrapPhase.loading;
  String? _errorMessage;
  String _storeUrl = '';
  String _maintenanceMessage = '';
  bool _recheckInProgress = false;
  bool _firebaseScheduled = false;

  late final AppStatusService _appStatusService;

  @override
  void initState() {
    super.initState();
    _appStatusService = widget.appStatusService ?? AppStatusService();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_run());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _phase == _BootstrapPhase.ready &&
        !_recheckInProgress) {
      unawaited(_recheckRemoteStatus(showLoading: false));
    }
  }

  Future<void> _run() async {
    try {
      await AppBootstrap.prepareCore();
      await _recheckRemoteStatus(showLoading: true);
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

  Future<void> _recheckRemoteStatus({required bool showLoading}) async {
    if (_recheckInProgress) return;
    _recheckInProgress = true;

    if (showLoading && mounted) {
      setState(() {
        _phase = _BootstrapPhase.loading;
        _errorMessage = null;
      });
    }

    try {
      final status = await _appStatusService.checkStatus();
      if (!mounted) return;

      if (status.maintenanceMode) {
        setState(() {
          _phase = _BootstrapPhase.maintenance;
          _maintenanceMessage = status.maintenanceMessage;
        });
        return;
      }

      if (status.forceUpdate) {
        setState(() {
          _phase = _BootstrapPhase.forceUpdate;
          _storeUrl = status.storeUrl;
        });
        return;
      }

      if (!InjectionContainer.isInitialized) {
        InjectionContainer.init();
      }

      if (!mounted) return;
      setState(() => _phase = _BootstrapPhase.ready);

      if (!_firebaseScheduled) {
        _firebaseScheduled = true;
        unawaited(AppBootstrap.initFirebaseAndNotifications());
      }
    } catch (e, st) {
      debugPrint('Remote status recheck failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _BootstrapPhase.error;
        _errorMessage = ApiErrorMapper.fromObject(
          e,
          fallback: 'Unable to start the app. Please try again.',
        );
      });
    } finally {
      _recheckInProgress = false;
    }
  }

  Future<void> _retry() {
    if (_phase == _BootstrapPhase.error) {
      return _run();
    }
    return _recheckRemoteStatus(showLoading: true);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _BootstrapPhase.ready:
        return const MyApp();
      case _BootstrapPhase.maintenance:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: MaintenanceScreen(
            onRetry: _retry,
            message: _maintenanceMessage,
          ),
        );
      case _BootstrapPhase.forceUpdate:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: ForceUpdateScreen(
            storeUrl: _storeUrl,
            onRetry: _retry,
          ),
        );
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
                      onPressed: () => unawaited(_retry()),
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

enum _BootstrapPhase { loading, ready, error, maintenance, forceUpdate }
