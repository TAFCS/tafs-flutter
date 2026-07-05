import 'dart:io';

import 'package:local_auth/local_auth.dart';

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
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Sign in to TAFS',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
