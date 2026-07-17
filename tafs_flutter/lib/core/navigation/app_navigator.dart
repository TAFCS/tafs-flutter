import 'package:flutter/material.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/support_tickets/presentation/pages/ticket_thread_page.dart';
import '../../features/support_tickets/staff/presentation/pages/staff_ticket_thread_page.dart';
import '../../injection_container.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void navigateToSupportTicketThread(String ticketId) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;

  final authState = InjectionContainer.authBloc.state;
  if (authState is AuthAuthenticatedStaff) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffTicketThreadPage(
          ticketId: ticketId,
          staff: authState.staff,
        ),
      ),
    );
    return;
  }

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
