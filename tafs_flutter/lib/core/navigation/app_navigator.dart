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
