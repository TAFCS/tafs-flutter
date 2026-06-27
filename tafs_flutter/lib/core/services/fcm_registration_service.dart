import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bootstrap/app_bootstrap.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// Centralizes FCM permission, token fetch, and backend registration.
class FcmRegistrationService {
  FcmRegistrationService._();
  static final FcmRegistrationService instance = FcmRegistrationService._();

  bool _tokenRefreshListenerAttached = false;

  Future<void> ensureReady() => AppBootstrap.waitForFirebase();

  /// Android 12 and below: notifications are allowed at install time (no runtime prompt).
  /// Android 13+ (API 33): requires POST_NOTIFICATIONS runtime permission.
  Future<bool> requestAndroidPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) return false;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> isNotificationPermissionGranted() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    return (await Permission.notification.status).isGranted;
  }

  Future<String?> getDeviceType() async {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return null;
  }

  /// Fetches FCM token after Firebase init.
  ///
  /// Token registration works on all supported Android versions (API 24+), even when
  /// the user denies the notification permission on Android 13+.
  Future<String?> getToken() async {
    if (kIsWeb) return null;

    try {
      await ensureReady();
      await requestAndroidPermission();

      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[FcmRegistration] getToken failed: $e');
      return null;
    }
  }

  /// Registers the current device token with the backend (requires auth interceptor on [dio]).
  /// Returns true when the server acknowledged registration.
  Future<bool> registerWithBackend(Dio dio, {String? tokenOverride, bool staff = false}) async {
    if (kIsWeb) return false;

    final token = tokenOverride ?? await getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[FcmRegistration] registerWithBackend skipped: no FCM token');
      return false;
    }

    final deviceType = await getDeviceType();
    final prefix = token.substring(0, min(12, token.length));
    final path = staff ? '/auth/staff/mobile/fcm-token' : '/auth/parent/fcm-token';

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await dio.post(
          path,
          data: {
            'fcmToken': token,
            if (deviceType != null) 'deviceType': deviceType,
          },
        );
        debugPrint(
          '[FcmRegistration] registered token (prefix=$prefix..., device=$deviceType, staff=$staff)',
        );
        return true;
      } on DioException catch (e) {
        debugPrint(
          '[FcmRegistration] registerWithBackend failed '
          '(attempt ${attempt + 1}): ${e.response?.statusCode} ${e.response?.data}',
        );
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        debugPrint('[FcmRegistration] registerWithBackend failed: $e');
        break;
      }
    }

    return false;
  }

  void listenForTokenRefresh(
    Dio dio, {
    bool Function()? sessionIsStaff,
  }) {
    if (kIsWeb || _tokenRefreshListenerAttached) return;

    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        final isStaff = sessionIsStaff?.call() ?? false;
        registerWithBackend(
          dio,
          tokenOverride: newToken,
          staff: isStaff,
        );
      });
      _tokenRefreshListenerAttached = true;
    } catch (e, st) {
      debugPrint('[FcmRegistration] onTokenRefresh setup failed: $e\n$st');
    }
  }

  /// Resolves staff vs parent from [authBloc] when no callback is supplied.
  void listenForTokenRefreshWithAuth(Dio dio, AuthBloc authBloc) {
    listenForTokenRefresh(
      dio,
      sessionIsStaff: () => authBloc.state is AuthAuthenticatedStaff,
    );
  }
}
