import 'package:equatable/equatable.dart';
import '../../domain/entities/support_ticket.dart';

abstract class SupportTicketListEvent extends Equatable {
  const SupportTicketListEvent();
  @override
  List<Object?> get props => [];
}

class SupportTicketListLoadRequested extends SupportTicketListEvent {
  final bool open;
  const SupportTicketListLoadRequested({this.open = true});
  @override
  List<Object?> get props => [open];
}

class SupportTicketListSocketRefreshRequested extends SupportTicketListEvent {
  const SupportTicketListSocketRefreshRequested();
}

/// Zero unread for a ticket after the parent opened the thread (markRead).
/// Needed when entry is via in-app notification — the list is not reloaded on pop.
class SupportTicketListUnreadCleared extends SupportTicketListEvent {
  final String ticketId;
  const SupportTicketListUnreadCleared(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class SupportTicketListResetRequested extends SupportTicketListEvent {
  const SupportTicketListResetRequested();
}

abstract class SupportTicketListState extends Equatable {
  const SupportTicketListState();
  @override
  List<Object?> get props => [];
}

class SupportTicketListInitial extends SupportTicketListState {}

class SupportTicketListLoading extends SupportTicketListState {}

class SupportTicketListLoaded extends SupportTicketListState {
  final List<SupportTicket> openTickets;
  final List<SupportTicket> closedTickets;
  final bool showingOpen;

  const SupportTicketListLoaded({
    required this.openTickets,
    required this.closedTickets,
    this.showingOpen = true,
  });

  List<SupportTicket> get visible =>
      showingOpen ? openTickets : closedTickets;

  int get unreadTotal =>
      openTickets.fold(0, (sum, t) => sum + t.unreadByParent);

  @override
  List<Object?> get props => [openTickets, closedTickets, showingOpen];
}

class SupportTicketListError extends SupportTicketListState {
  final String message;
  const SupportTicketListError(this.message);
  @override
  List<Object?> get props => [message];
}
