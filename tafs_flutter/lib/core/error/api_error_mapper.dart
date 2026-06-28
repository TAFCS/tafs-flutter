import 'package:dio/dio.dart';

import 'failures.dart';

/// Maps API / network errors to short, user-friendly messages.
class ApiErrorMapper {
  static const int _maxMessageLength = 140;

  static const String defaultMessage =
      'Something went wrong. Please try again.';

  static const String networkMessage =
      'Unable to connect. Please check your internet connection.';

  static const String timeoutMessage =
      'Connection timed out. Please check your internet and try again.';

  static const String serverMessage =
      'Something went wrong on our end. Please try again later.';

  /// Extract a safe message from any thrown object.
  static String fromObject(
    Object error, {
    String fallback = defaultMessage,
    String? selfServiceForbiddenMessage,
  }) {
    if (error is Failure) {
      return fromFailure(error);
    }
    if (error is DioException) {
      return fromDioException(
        error,
        fallback: fallback,
        selfServiceForbiddenMessage: selfServiceForbiddenMessage,
      );
    }
    return fallback;
  }

  /// HR self-service endpoints (`/attendance/staff/me`, `/hr/payroll/me`).
  static String staffSelfServiceMessage(
    Object error, {
    required String featureLabel,
    String fallback = defaultMessage,
  }) {
    return fromObject(
      error,
      fallback: fallback,
      selfServiceForbiddenMessage:
          'You do not have access to your $featureLabel records. '
          'Ask HR to link your employee profile and grant self-service permissions.',
    );
  }

  static String fromFailure(Failure failure) {
    if (failure is InvalidCredentialsFailure) {
      return failure.message;
    }
    return sanitize(failure.message, fallback: defaultMessage);
  }

  static String fromDioException(
    DioException error, {
    String fallback = defaultMessage,
    String? selfServiceForbiddenMessage,
  }) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return timeoutMessage;
      case DioExceptionType.connectionError:
        return networkMessage;
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        break;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return serverMessage;
    }

    final backendMessage = _extractBackendMessage(error.response?.data);
    if (backendMessage != null) {
      return sanitize(backendMessage, fallback: fallback);
    }

    if (statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }

    if (statusCode == 403) {
      return selfServiceForbiddenMessage ??
          'You do not have permission to perform this action.';
    }

    if (statusCode == 404) {
      return 'The requested information could not be found.';
    }

    return fallback;
  }

  /// Strips technical noise and caps length for UI display.
  static String sanitize(
    String? raw, {
    String fallback = defaultMessage,
  }) {
    if (raw == null) return fallback;

    var message = raw.trim();
    if (message.isEmpty) return fallback;

    if (_looksTechnical(message)) {
      return fallback;
    }

    message = message.replaceAll(RegExp(r'\s+'), ' ');

    if (message.length > _maxMessageLength) {
      message = '${message.substring(0, _maxMessageLength - 3)}...';
    }

    return message;
  }

  static String? _extractBackendMessage(dynamic data) {
    if (data is! Map) return null;

    final message = data['message'];
    if (message is String) {
      final trimmed = message.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (message is List) {
      final parts = message
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .take(2)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join(' ');
    }

    return null;
  }

  /// UI-safe message for a [Failure].
  static String userMessage(Failure failure) => fromFailure(failure);

  static bool _looksTechnical(String message) {
    final lower = message.toLowerCase();
    return message.startsWith('{') ||
        message.startsWith('[') ||
        lower.contains('dioexception') ||
        lower.contains('socketexception') ||
        lower.contains('formatexception') ||
        lower.contains('type ') && lower.contains(' is not a subtype') ||
        lower.contains('http status error') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('failed host lookup') ||
        lower.contains('handshake error') ||
        lower.contains('serverfailure(') ||
        lower.contains('exception:');
  }
}
