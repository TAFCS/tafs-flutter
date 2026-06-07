import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/support_ticket_repository.dart';

class TicketThreadState {
  final SupportTicket? ticket;
  final List<TicketMessage> messages;
  final bool loading;
  final bool sending;
  final String? error;

  const TicketThreadState({
    this.ticket,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.error,
  });

  TicketThreadState copyWith({
    SupportTicket? ticket,
    List<TicketMessage>? messages,
    bool? loading,
    bool? sending,
    String? error,
  }) =>
      TicketThreadState(
        ticket: ticket ?? this.ticket,
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        error: error,
      );
}

class TicketThreadCubit extends Cubit<TicketThreadState> {
  final SupportTicketRepository repository;
  StreamSubscription<TicketMessage>? _sub;
  String? _activeTicketId;

  TicketThreadCubit({required this.repository}) : super(const TicketThreadState());

  Future<void> load(String ticketId) async {
    _activeTicketId = ticketId;
    await _sub?.cancel();
    emit(state.copyWith(loading: true, error: null));
    try {
      await repository.enterTicket(ticketId);
      await repository.markRead(ticketId);
      final detail = await repository.getTicketDetail(ticketId);
      emit(TicketThreadState(
        ticket: detail.ticket,
        messages: detail.messages.reversed.toList(),
        loading: false,
      ));
      _sub = repository.onTicketMessage.listen((msg) {
        if (msg.ticketId != ticketId) return;
        if (state.messages.any((m) => m.id == msg.id)) return;
        emit(state.copyWith(messages: [...state.messages, msg]));
      });
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> sendText(String content) async {
    final ticket = state.ticket;
    if (ticket == null || content.trim().isEmpty) return;
    emit(state.copyWith(sending: true));
    try {
      await repository.sendMessage(
        ticketId: ticket.id,
        messageType: 'TEXT',
        content: content.trim(),
      );
      emit(state.copyWith(sending: false));
    } catch (e) {
      emit(state.copyWith(sending: false, error: e.toString()));
    }
  }

  Future<void> sendMedia({
    required String messageType,
    required String content,
    required Map<String, dynamic> mediaMetadata,
  }) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    emit(state.copyWith(sending: true));
    try {
      await repository.sendMessage(
        ticketId: ticket.id,
        messageType: messageType,
        content: content,
        mediaMetadata: mediaMetadata,
      );
      emit(state.copyWith(sending: false));
    } catch (e) {
      emit(state.copyWith(sending: false, error: e.toString()));
    }
  }

  Future<void> closeTicket() async {
    final ticket = state.ticket;
    if (ticket == null) return;
    await repository.closeTicket(ticket.id);
    await load(ticket.id);
  }

  @override
  Future<void> close() async {
    final id = _activeTicketId;
    if (id != null) await repository.leaveTicket(id);
    await _sub?.cancel();
    return super.close();
  }
}
