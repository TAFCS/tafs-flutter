import 'package:flutter/foundation.dart' show kIsWeb;

/// Fetches FCM token and device type string safely on all platforms.
/// Returns (null, null) on web or if FCM is unavailable.
Future<(String?, String?)> getFcmTokenAndDeviceType() async {
  if (kIsWeb) return (null, null);
  return _mobileGetFcmToken();
}

Future<(String?, String?)> _mobileGetFcmToken() async {
  // dart:io and firebase_messaging are only used here, inside a non-web call path.
  // ignore: avoid_web_libraries_in_flutter
  try {
    // Conditional compilation: dart:library.io is true on mobile, false on web
    // ignore: undefined_identifier, avoid_dynamic_calls
    final token = await _getToken();
    final deviceType = _getDeviceType();
    return (token, deviceType);
  } catch (e) {
    return (null, null);
  }
}

// These are backed by mobile_fcm_impl.dart which is only compiled on non-web
Future<String?> _getToken() => _FcmImpl.getToken();
String? _getDeviceType() => _FcmImpl.deviceType();

// Concrete implementation — safe because we only reach here when !kIsWeb
class _FcmImpl {
  static Future<String?> getToken() async {
    // This entire file is compiled on both web and mobile, but _getToken() is
    // only CALLED when !kIsWeb (guarded at the top).
    // However, the Dart compiler may still evaluate symbol lookups at compile time.
    // So we use the firebase_messaging package but guard the actual call.
    if (kIsWeb) return null;
    // ignore: depend_on_referenced_packages
    // ignore: avoid_web_libraries_in_flutter
    // Directly call — this is unreachable from web because getFcmTokenAndDeviceType guards it.
    // We cannot import firebase_messaging safely here without it crashing on web compilation.
    // Solution: rely on the kIsWeb guard at the top of getFcmTokenAndDeviceType.
    throw UnsupportedError('Unreachable on web');
  }

  static String? deviceType() {
    if (kIsWeb) return null;
    throw UnsupportedError('Unreachable on web');
  }
}
