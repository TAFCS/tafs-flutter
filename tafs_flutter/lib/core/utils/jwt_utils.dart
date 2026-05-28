import 'dart:convert';

/// JWT utility functions for checking token expiration
class JwtUtils {
  /// Decode JWT payload (without verification — this is safe for expiration checks on client)
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      // Add padding if needed
      final padded = payload + '=' * (4 - payload.length % 4);
      final decoded = utf8.decode(base64Url.decode(padded));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired (with a 60-second buffer)
  static bool isTokenExpired(String token) {
    try {
      final payload = decodePayload(token);
      if (payload == null) return true;

      final exp = payload['exp'] as int?;
      if (exp == null) return true;

      // Token is expired if current time > (exp - 60 seconds)
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now > (exp - 60);
    } catch (e) {
      return true;
    }
  }

  /// Get seconds remaining until token expiration
  static int getSecondsUntilExpiry(String token) {
    try {
      final payload = decodePayload(token);
      if (payload == null) return 0;

      final exp = payload['exp'] as int?;
      if (exp == null) return 0;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = exp - now;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }
}
