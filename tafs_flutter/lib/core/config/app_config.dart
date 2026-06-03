import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves API base URL for all network clients.
///
/// Priority: `--dart-define=API_BASE_URL=...` → `.env` → release default → dev localhost.
class AppConfig {
  AppConfig._();

  /// Production backend (matches tafs-webapp Railway deploy).
  static const String productionApiBaseUrl =
      'https://tafs-backend-production.up.railway.app/api/v1';

  static const String _devApiBaseUrl = 'http://127.0.0.1:8080/api/v1';

  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;

    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['API_BASE_URL']?.trim();
      if (fromEnv != null && fromEnv.isNotEmpty) {
        return fromEnv;
      }
    }

    if (kReleaseMode) return productionApiBaseUrl;
    return _devApiBaseUrl;
  }
}
