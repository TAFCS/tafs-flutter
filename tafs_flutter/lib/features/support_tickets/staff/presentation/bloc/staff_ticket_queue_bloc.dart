import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../../domain/repositories/staff_support_ticket_repository.dart';
import '../../support_ticket_staff_access.dart';

class StaffTicketQueueState {
  final StaffQueueTab tab;
  final List<StaffSupportTicket> items;
  final String? selectedId;
  final bool loading;
  final String? error;

  const StaffTicketQueueState({
    this.tab = StaffQueueTab.myQueue,
    this.items = const [],
    this.selectedId,
    this.loading = false,
    this.error,
  });

  StaffTicketQueueState copyWith({
    StaffQueueTab? tab,
    List<StaffSupportTicket>? items,
    String? selectedId,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearSelection = false,
  }) =>
      StaffTicketQueueState(
        tab: tab ?? this.tab,
        items: items ?? this.items,
        selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

abstract class StaffTicketQueueEvent {}

class StaffQueueInit extends StaffTicketQueueEvent {
  final String role;
  StaffQueueInit(this.role);
}

class StaffQueueTabChanged extends StaffTicketQueueEvent {
  final StaffQueueTab tab;
  StaffQueueTabChanged(this.tab);
}

class StaffQueueRefreshRequested extends StaffTicketQueueEvent {}

class StaffQueueTicketSelected extends StaffTicketQueueEvent {
  final String? ticketId;
  StaffQueueTicketSelected(this.ticketId);
}

class StaffQueueSocketMessage extends StaffTicketQueueEvent {}

class StaffQueueReset extends StaffTicketQueueEvent {}

class StaffTicketQueueBloc extends Bloc<StaffTicketQueueEvent, StaffTicketQueueState> {
  final StaffSupportTicketRepository repository;
  StreamSubscription? _socketSub;

  StaffTicketQueueBloc({required this.repository})
      : super(const StaffTicketQueueState()) {
    on<StaffQueueInit>(_onInit);
    on<StaffQueueTabChanged>(_onTabChanged);
    on<StaffQueueRefreshRequested>(_onRefresh);
    on<StaffQueueTicketSelected>(_onSelect);
    on<StaffQueueSocketMessage>(_onSocket);
    on<StaffQueueReset>(_onReset);
  }

  Future<void> _onInit(
    StaffQueueInit event,
    Emitter<StaffTicketQueueState> emit,
  ) async {
    if (_socketSub != null) return;
    final tab = defaultQueueTabForRole(event.role);
    emit(state.copyWith(tab: tab));
    add(StaffQueueRefreshRequested());
    await repository.connectSocket();
    await _socketSub?.cancel();
    _socketSub = repository.onTicketQueueChanged.listen((_) {
      add(StaffQueueSocketMessage());
    });
  }

  Future<void> _onTabChanged(
    StaffQueueTabChanged event,
    Emitter<StaffTicketQueueState> emit,
  ) async {
    emit(state.copyWith(tab: event.tab, clearSelection: true));
    add(StaffQueueRefreshRequested());
  }

  Future<void> _onRefresh(
    StaffQueueRefreshRequested event,
    Emitter<StaffTicketQueueState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final List<StaffSupportTicket> items;
      switch (state.tab) {
        case StaffQueueTab.financeQueue:
          items = await repository.fetchFinanceQueue();
        case StaffQueueTab.oversight:
          items = await repository.fetchOversightQueue();
        case StaffQueueTab.closed:
          items = await repository.fetchClosed();
        case StaffQueueTab.myQueue:
          items = await repository.fetchMyQueue();
      }
      items.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Failed to load queue. Pull to refresh.',
      ));
    }
  }

  void _onSelect(
    StaffQueueTicketSelected event,
    Emitter<StaffTicketQueueState> emit,
  ) {
    emit(state.copyWith(selectedId: event.ticketId));
  }

  void _onSocket(
    StaffQueueSocketMessage event,
    Emitter<StaffTicketQueueState> emit,
  ) {
    add(StaffQueueRefreshRequested());
  }

  Future<void> _onReset(
    StaffQueueReset event,
    Emitter<StaffTicketQueueState> emit,
  ) async {
    await _socketSub?.cancel();
    _socketSub = null;
    await repository.disconnectSocket();
    emit(const StaffTicketQueueState());
  }

  @override
  Future<void> close() {
    _socketSub?.cancel();
    return super.close();
  }
}
