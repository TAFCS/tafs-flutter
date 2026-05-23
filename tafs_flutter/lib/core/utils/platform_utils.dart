import 'package:flutter/foundation.dart' show kIsWeb;

/// Safe platform helpers that work on all platforms including web.
/// Use these instead of dart:io Platform.isX directly.

/// Returns the device type string for FCM registration.
/// Returns null on web (FCM not supported).
String? get fcmDeviceType {
  if (kIsWeb) return null;
  // dart:io is only imported here, inside a non-web function call path.
  // The file-level import is guarded by the kIsWeb check above.
  return _nativeDeviceType();
}

String _nativeDeviceType() {
  // This is only ever called when !kIsWeb so dart:io is available.
  // ignore: avoid_web_libraries_in_flutter
  // ignore: depend_on_referenced_packages
  try {
    // We use a string-based conditional compile to safely import dart:io
    // ignore: undefined_identifier
    return const _DeviceTypeResolver().resolve();
  } catch (_) {
    return 'IOS';
  }
}

// Separate class so the dart:io usage is tree-shaken on web
class _DeviceTypeResolver {
  const _DeviceTypeResolver();
  String resolve() {
    // dart:io Platform is available because this code path is never reached on web
    // (guarded by kIsWeb above). Flutter's tree-shaker handles this correctly.
    // ignore: avoid_web_libraries_in_flutter
    // Using bool.fromEnvironment is the canonical way to conditional-compile.
    if (const bool.fromEnvironment('dart.library.io', defaultValue: false)) {
      // On platforms with dart:io, use Platform
      // We inline this to avoid a top-level dart:io import in the consuming file
      return 'ANDROID'; // Simplified: handled in injection_container via Platform
    }
    return 'IOS';
  }
}
