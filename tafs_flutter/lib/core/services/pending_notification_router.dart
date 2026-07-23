/// Queues a single notification deep-link until auth + navigator are ready.
///
/// Cold-start FCM / local-notification taps often arrive while [AuthBloc] is
/// still checking the session. Without a queue those taps are dropped.
class PendingNotificationRouter {
  Map<String, dynamic>? _pending;

  Map<String, dynamic>? get pending =>
      _pending == null ? null : Map<String, dynamic>.from(_pending!);

  bool get hasPending => _pending != null;

  /// Store (or replace) the launch payload when the user is not ready yet.
  void queue(Map<String, dynamic> data) {
    _pending = Map<String, dynamic>.from(data);
  }

  /// Drop a stale payload (e.g. on logout) so it cannot fire for another user.
  void clear() {
    _pending = null;
  }

  /// When authenticated and the navigator exists, consume and return the
  /// pending payload. Otherwise leave it queued and return null.
  Map<String, dynamic>? flushIfReady({
    required bool isAuthenticated,
    required bool hasNavigator,
  }) {
    if (!isAuthenticated || !hasNavigator) return null;
    final data = _pending;
    if (data == null) return null;
    _pending = null;
    return Map<String, dynamic>.from(data);
  }
}
