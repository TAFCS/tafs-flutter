import 'package:flutter/material.dart';
import '../../features/support_tickets/presentation/pages/ticket_thread_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void navigateToSupportTicketThread(String ticketId) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TicketThreadPage(ticketId: ticketId),
    ),
  );
}

/// Requests that [MainShellPage] switch its bottom-nav tab to the given
/// index. Listened to by `_MainShellPageState`, which resets this back to
/// null once handled.
final ValueNotifier<int?> mainShellTabRequest = ValueNotifier<int?>(null);

void switchToFeesTab() {
  mainShellTabRequest.value = 1;
}

void switchToHomeTab() {
  mainShellTabRequest.value = 0;
}
