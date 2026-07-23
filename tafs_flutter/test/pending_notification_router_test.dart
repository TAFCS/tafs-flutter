import 'package:flutter_test/flutter_test.dart';
import 'package:tafs_flutter/core/services/pending_notification_router.dart';

void main() {
  group('PendingNotificationRouter', () {
    late PendingNotificationRouter router;

    setUp(() {
      router = PendingNotificationRouter();
    });

    test('queues when unauthed and keeps payload until flush', () {
      router.queue({
        'type': 'SUPPORT_TICKET_MESSAGE',
        'ticketId': 't1',
      });

      expect(router.hasPending, isTrue);
      expect(
        router.flushIfReady(isAuthenticated: false, hasNavigator: false),
        isNull,
      );
      expect(router.hasPending, isTrue);

      expect(
        router.flushIfReady(isAuthenticated: true, hasNavigator: false),
        isNull,
      );
      expect(router.hasPending, isTrue);
    });

    test('flushes once when authed and navigator ready', () {
      router.queue({
        'type': 'SUPPORT_TICKET_MESSAGE',
        'ticketId': 't1',
      });

      final first = router.flushIfReady(
        isAuthenticated: true,
        hasNavigator: true,
      );
      expect(first, {
        'type': 'SUPPORT_TICKET_MESSAGE',
        'ticketId': 't1',
      });
      expect(router.hasPending, isFalse);

      final second = router.flushIfReady(
        isAuthenticated: true,
        hasNavigator: true,
      );
      expect(second, isNull);
    });

    test('clear drops pending so logout cannot leak to next user', () {
      router.queue({'type': 'SUPPORT_TICKET_MESSAGE', 'ticketId': 't1'});
      router.clear();
      expect(router.hasPending, isFalse);
      expect(
        router.flushIfReady(isAuthenticated: true, hasNavigator: true),
        isNull,
      );
    });

    test('queue replaces previous pending payload', () {
      router.queue({'ticketId': 'old'});
      router.queue({'ticketId': 'new'});
      expect(router.pending?['ticketId'], 'new');
    });
  });
}
