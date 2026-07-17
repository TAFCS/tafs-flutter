import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import 'support_ticket_list_event.dart';
import 'support_ticket_list_state.dart';

class SupportTicketListBloc
    extends Bloc<SupportTicketListEvent, SupportTicketListState> {
  final SupportTicketRepository repository;
  StreamSubscription? _ticketSub;

  SupportTicketListBloc({required this.repository})
      : super(SupportTicketListInitial()) {
    on<SupportTicketListLoadRequested>(_onLoad);
    on<SupportTicketListSocketRefreshRequested>(_onSocketRefresh);
    on<SupportTicketListResetRequested>((event, emit) {
      _ticketSub?.cancel();
      _ticketSub = null;
      emit(SupportTicketListInitial());
    });
  }

  Future<void> _onLoad(
    SupportTicketListLoadRequested event,
    Emitter<SupportTicketListState> emit,
  ) async {
    emit(SupportTicketListLoading());
    try {
      await repository.connectSocket();
      _ticketSub ??= repository.onTicketMessage.listen(
        (_) {
          add(const SupportTicketListSocketRefreshRequested());
        },
        onError: (_) {},
        cancelOnError: false,
      );
      final open = await repository.listTickets(open: true);
      final closed = await repository.listTickets(open: false);
      open.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      closed.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      emit(SupportTicketListLoaded(
        openTickets: open,
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
        openTickets: open,
        closedTickets: closed,
        showingOpen: current.showingOpen,
      ));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _ticketSub?.cancel();
    return super.close();
  }
}
