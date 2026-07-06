import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAuthFailure {
  cancelled,
  notEnrolled,
  notAvailable,
  unknown,
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.success,
    this.failure,
  });

  final bool success;
  final BiometricAuthFailure? failure;
}

class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  Future<bool> canUseBiometrics() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<String> getBiometricLabel() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      if (Platform.isIOS) {
        if (types.contains(BiometricType.face)) return 'Face ID';
        if (types.contains(BiometricType.fingerprint)) return 'Touch ID';
      }
      if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
      if (types.contains(BiometricType.face)) return 'Face unlock';
    } catch (_) {
      // Fall through to default label.
    }
    return 'Biometrics';
  }

  Future<bool> authenticate() async {
    final result = await authenticateDetailed();
    return result.success;
  }

  Future<BiometricAuthResult> authenticateDetailed() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      final hasBiometricHardware = types.isNotEmpty;

      final success = await _localAuth.authenticate(
        localizedReason: 'Sign in to TAFS',
        options: AuthenticationOptions(
          biometricOnly: Platform.isIOS || hasBiometricHardware,
          stickyAuth: true,
          useErrorDialogs: Platform.isAndroid,
        ),
      );

      if (success) {
        return const BiometricAuthResult(success: true);
      }
      return const BiometricAuthResult(
        success: false,
        failure: BiometricAuthFailure.cancelled,
      );
    } on PlatformException catch (e) {
      debugPrint('[BiometricAuth] ${e.code}: ${e.message}');
      return BiometricAuthResult(
        success: false,
        failure: _mapPlatformFailure(e.code),
      );
    } catch (e) {
      debugPrint('[BiometricAuth] authenticate failed: $e');
      return const BiometricAuthResult(
        success: false,
        failure: BiometricAuthFailure.unknown,
      );
    }
  }

  BiometricAuthFailure _mapPlatformFailure(String? code) {
    switch (code) {
      case 'NotEnrolled':
      case 'notEnrolled':
        return BiometricAuthFailure.notEnrolled;
      case 'NotAvailable':
      case 'notAvailable':
      case 'PasscodeNotSet':
      case 'passcodeNotSet':
        return BiometricAuthFailure.notAvailable;
      case 'UserCanceled':
      case 'Canceled':
      case 'auth_in_progress':
      case 'systemCanceled':
        return BiometricAuthFailure.cancelled;
      default:
        return BiometricAuthFailure.unknown;
    }
  }

  String failureMessage({
    required String label,
    required BiometricAuthFailure failure,
  }) {
    switch (failure) {
      case BiometricAuthFailure.notEnrolled:
        return 'No $label enrolled on this device. Add one in Settings, then try again.';
      case BiometricAuthFailure.notAvailable:
        return 'Set a screen lock (PIN/pattern/password) and enroll $label in Settings.';
      case BiometricAuthFailure.cancelled:
        return '$label authentication cancelled';
      case BiometricAuthFailure.unknown:
        return '$label setup was not completed. Rebuild the app after updating.';
    }
  }
}
