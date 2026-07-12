import 'package:flutter/foundation.dart';

/// Tracks whether a logout is currently in flight so the app root can show a
/// screen-locking loader for its duration. Reset back to false once
/// [AuthState] transitions to `AuthUnauthenticated` (see auth_gate.dart).
final ValueNotifier<bool> isLoggingOutNotifier = ValueNotifier<bool>(false);
