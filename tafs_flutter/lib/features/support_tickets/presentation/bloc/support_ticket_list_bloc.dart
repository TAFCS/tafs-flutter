import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import '../utils/ticket_thread_presence.dart';
import 'support_ticket_list_event.dart';
import 'support_ticket_list_state.dart';

class SupportTicketListBloc
    extends Bloc<SupportTicketListEvent, SupportTicketListState> {
  final SupportTicketRepository repository;
  StreamSubscription? _ticketSub;
  StreamSubscription? _queueSub;

  /// Tickets the parent has opened this session — keep badge at 0 even if a
  /// concurrent list refresh still returns the pre-markRead unread count.
  final Set<String> _locallyReadTicketIds = {};

  SupportTicketListBloc({required this.repository})
      : super(SupportTicketListInitial()) {
    on<SupportTicketListLoadRequested>(_onLoad);
    on<SupportTicketListSocketRefreshRequested>(_onSocketRefresh);
    on<SupportTicketListUnreadCleared>(_onUnreadCleared);
    on<SupportTicketListResetRequested>((event, emit) {
      _ticketSub?.cancel();
      _queueSub?.cancel();
      _ticketSub = null;
      _queueSub = null;
      _locallyReadTicketIds.clear();
      emit(SupportTicketListInitial());
    });
  }

  List<SupportTicket> _applyUnreadOverrides(List<SupportTicket> open) {
    final activeId = TicketThreadPresence.activeTicketId;
    if (activeId == null && _locallyReadTicketIds.isEmpty) return open;
    return open
        .map((t) {
          if (t.id == activeId || _locallyReadTicketIds.contains(t.id)) {
            return t.copyWith(unreadByParent: 0);
          }
          return t;
        })
        .toList();
  }

  void _onUnreadCleared(
    SupportTicketListUnreadCleared event,
    Emitter<SupportTicketListState> emit,
  ) {
    _locallyReadTicketIds.add(event.ticketId);
    final current = state;
    if (current is! SupportTicketListLoaded) return;
    emit(SupportTicketListLoaded(
      openTickets: _applyUnreadOverrides(current.openTickets),
      closedTickets: current.closedTickets,
      showingOpen: current.showingOpen,
    ));
  }

  Future<void> _onLoad(
    SupportTicketListLoadRequested event,
    Emitter<SupportTicketListState> emit,
  ) async {
    emit(SupportTicketListLoading());
    try {
      await repository.connectSocket();
      _ticketSub ??= repository.onTicketMessage.listen(
        (msg) {
          // New message while not viewing → allow unread badge again.
          if (!TicketThreadPresence.isViewing(msg.ticketId)) {
            _locallyReadTicketIds.remove(msg.ticketId);
          }
          add(const SupportTicketListSocketRefreshRequested());
        },
        onError: (_) {},
        cancelOnError: false,
      );
      _queueSub ??= repository.onTicketQueueChanged.listen(
        (_) => add(const SupportTicketListSocketRefreshRequested()),
        onError: (_) {},
        cancelOnError: false,
      );
      final open = await repository.listTickets(open: true);
      final closed = await repository.listTickets(open: false);
      open.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      closed.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      emit(SupportTicketListLoaded(
        openTickets: _applyUnreadOverrides(open),
        closedTickets: closed,
        showingOpen: event.open,
      ));
    } catch (e) {
      emit(SupportTicketListError('Could not load your queries. Please try again.'));
    }
  }

  Future<void> _onSocketRefresh(
    SupportTicketListSocketRefreshRequested event,
    Emitter<SupportTicketListState> emit,
  ) async {
    final current = state;
    if (current is! SupportTicketListLoaded) return;
    try {
      final open = await repository.listTickets(open: true);
      final closed = await repository.listTickets(open: false);
      open.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      closed.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      emit(SupportTicketListLoaded(
        openTickets: _applyUnreadOverrides(open),
        closedTickets: closed,
        showingOpen: current.showingOpen,
      ));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _ticketSub?.cancel();
    _queueSub?.cancel();
    return super.close();
  }
}
