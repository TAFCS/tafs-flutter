import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedCredentials {
  const SavedCredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

class SavedCredentialsService {
  SavedCredentialsService(this._storage);

  final FlutterSecureStorage _storage;

  static const _parentEnabledKey = 'biometric_parent_enabled';
  static const _parentUsernameKey = 'biometric_parent_username';
  static const _parentPasswordKey = 'biometric_parent_password';
  static const _staffEnabledKey = 'biometric_staff_enabled';
  static const _staffUsernameKey = 'biometric_staff_username';
  static const _staffPasswordKey = 'biometric_staff_password';
  static const _parentDeclinedKey = 'biometric_parent_prompt_declined';
  static const _staffDeclinedKey = 'biometric_staff_prompt_declined';

  String _enabledKey({required bool isStaff}) =>
      isStaff ? _staffEnabledKey : _parentEnabledKey;

  String _usernameKey({required bool isStaff}) =>
      isStaff ? _staffUsernameKey : _parentUsernameKey;

  String _passwordKey({required bool isStaff}) =>
      isStaff ? _staffPasswordKey : _parentPasswordKey;

  Future<bool> isBiometricEnabled({required bool isStaff}) async {
    final value = await _storage.read(key: _enabledKey(isStaff: isStaff));
    return value == 'true';
  }

  Future<bool> hasSavedCredentials({required bool isStaff}) async {
    if (!await isBiometricEnabled(isStaff: isStaff)) return false;
    final username = await _storage.read(key: _usernameKey(isStaff: isStaff));
    final password = await _storage.read(key: _passwordKey(isStaff: isStaff));
    return username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  Future<SavedCredentials?> load({required bool isStaff}) async {
    if (!await hasSavedCredentials(isStaff: isStaff)) return null;
    final username = await _storage.read(key: _usernameKey(isStaff: isStaff));
    final password = await _storage.read(key: _passwordKey(isStaff: isStaff));
    if (username == null || password == null) return null;
    return SavedCredentials(username: username, password: password);
  }

  Future<void> save({
    required bool isStaff,
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _enabledKey(isStaff: isStaff), value: 'true');
    await _storage.write(key: _usernameKey(isStaff: isStaff), value: username);
    await _storage.write(key: _passwordKey(isStaff: isStaff), value: password);
  }

  Future<void> clear({required bool isStaff}) async {
    await _storage.delete(key: _enabledKey(isStaff: isStaff));
    await _storage.delete(key: _usernameKey(isStaff: isStaff));
    await _storage.delete(key: _passwordKey(isStaff: isStaff));
    await _storage.delete(key: _declinedKey(isStaff: isStaff));
  }

  String _declinedKey({required bool isStaff}) =>
      isStaff ? _staffDeclinedKey : _parentDeclinedKey;

  Future<bool> hasDeclinedBiometricPrompt({required bool isStaff}) async {
    final value = await _storage.read(key: _declinedKey(isStaff: isStaff));
    return value == 'true';
  }

  Future<void> setDeclinedBiometricPrompt({required bool isStaff}) async {
    await _storage.write(key: _declinedKey(isStaff: isStaff), value: 'true');
  }
}
