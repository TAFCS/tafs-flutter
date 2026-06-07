import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import '../utils/ticket_thread_presence.dart';

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
    bool clearError = false,
  }) =>
      TicketThreadState(
        ticket: ticket ?? this.ticket,
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        error: clearError ? null : (error ?? this.error),
      );
}

class TicketThreadCubit extends Cubit<TicketThreadState> {
  final SupportTicketRepository repository;
  StreamSubscription<TicketMessage>? _sub;
  String? _activeTicketId;

  TicketThreadCubit({required this.repository}) : super(const TicketThreadState());

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('403') || text.toLowerCase().contains('forbidden')) {
      return 'You do not have access to this query.';
    }
    if (text.contains('404')) return 'This query could not be found.';
    if (text.contains('SocketException') || text.contains('Connection')) {
      return 'Connection problem. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _appendMessage(TicketMessage msg) {
    if (state.messages.any((m) => m.id == msg.id)) return;
    emit(state.copyWith(messages: [...state.messages, msg], clearError: true));
  }

  Future<void> load(String ticketId) async {
    _activeTicketId = ticketId;
    TicketThreadPresence.activeTicketId = ticketId;
    await _sub?.cancel();
    emit(state.copyWith(loading: true, clearError: true));
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
        _appendMessage(msg);
      });
    } catch (e) {
      emit(state.copyWith(loading: false, error: _friendlyError(e)));
    }
  }

  Future<void> sendText(String content) async {
    final ticket = state.ticket;
    if (ticket == null || content.trim().isEmpty) return;
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: 'TEXT',
        content: content.trim(),
      );
      _appendMessage(msg);
      emit(state.copyWith(sending: false));
    } catch (e) {
      emit(state.copyWith(sending: false, error: _friendlyError(e)));
    }
  }

  Future<void> sendMedia({
    required String messageType,
    required String content,
    required Map<String, dynamic> mediaMetadata,
  }) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: messageType,
        content: content,
        mediaMetadata: mediaMetadata,
      );
      _appendMessage(msg);
      emit(state.copyWith(sending: false));
    } catch (e) {
      emit(state.copyWith(sending: false, error: _friendlyError(e)));
    }
  }

  Future<void> closeTicket() async {
    final ticket = state.ticket;
    if (ticket == null) return;
    try {
      await repository.closeTicket(ticket.id);
      await load(ticket.id);
    } catch (e) {
      emit(state.copyWith(error: _friendlyError(e)));
    }
  }

  @override
  Future<void> close() async {
    final id = _activeTicketId;
    if (id != null) await repository.leaveTicket(id);
    if (TicketThreadPresence.activeTicketId == id) {
      TicketThreadPresence.activeTicketId = null;
    }
    await _sub?.cancel();
    return super.close();
  }
}
