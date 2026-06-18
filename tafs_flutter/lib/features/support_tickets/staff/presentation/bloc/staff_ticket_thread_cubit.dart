import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/ticket_message.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../../data/models/staff_support_ticket_dto.dart';
import '../../domain/repositories/staff_support_ticket_repository.dart';

class StaffTicketThreadState {
  final StaffSupportTicket? ticket;
  final List<TicketMessage> messages;
  final bool loading;
  final bool sending;
  final bool actionLoading;
  final bool isSocketConnected;
  final String? error;
  final String? actionError;

  const StaffTicketThreadState({
    this.ticket,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.actionLoading = false,
    this.isSocketConnected = true,
    this.error,
    this.actionError,
  });

  StaffTicketThreadState copyWith({
    StaffSupportTicket? ticket,
    List<TicketMessage>? messages,
    bool? loading,
    bool? sending,
    bool? actionLoading,
    bool? isSocketConnected,
    String? error,
    String? actionError,
    bool clearError = false,
    bool clearActionError = false,
  }) =>
      StaffTicketThreadState(
        ticket: ticket ?? this.ticket,
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        actionLoading: actionLoading ?? this.actionLoading,
        isSocketConnected: isSocketConnected ?? this.isSocketConnected,
        error: clearError ? null : (error ?? this.error),
        actionError: clearActionError ? null : (actionError ?? this.actionError),
      );
}

class StaffTicketThreadCubit extends Cubit<StaffTicketThreadState> {
  final StaffSupportTicketRepository repository;
  StreamSubscription<TicketMessage>? _sub;
  StreamSubscription<Map<String, dynamic>>? _pendingSub;
  StreamSubscription<Map<String, dynamic>>? _reviewedSub;
  StreamSubscription<void>? _connectSub;
  StreamSubscription<void>? _disconnectSub;
  String? _activeTicketId;

  StaffTicketThreadCubit({required this.repository})
      : super(const StaffTicketThreadState());

  Future<void> load(String ticketId) async {
    _activeTicketId = ticketId;
    await _sub?.cancel();
    await _pendingSub?.cancel();
    await _reviewedSub?.cancel();
    await _connectSub?.cancel();
    await _disconnectSub?.cancel();
    emit(state.copyWith(
      loading: true,
      clearError: true,
      clearActionError: true,
      isSocketConnected: repository.isSocketConnected,
    ));
    _connectSub = repository.onSocketConnect.listen((_) {
      emit(state.copyWith(isSocketConnected: true));
    });
    _disconnectSub = repository.onSocketDisconnect.listen((_) {
      emit(state.copyWith(isSocketConnected: false));
    });
    try {
      await repository.enterTicket(ticketId);
      await repository.markRead(ticketId);
      final detail = await repository.fetchDetail(ticketId);
      emit(StaffTicketThreadState(
        ticket: detail.ticket,
        messages: detail.messages.reversed.toList(),
        loading: false,
        isSocketConnected: repository.isSocketConnected,
      ));
      _sub = repository.onTicketMessage.listen((msg) {
        if (msg.ticketId != ticketId) return;
        if (state.messages.any((m) => m.id == msg.id)) return;
        emit(state.copyWith(messages: [...state.messages, msg]));
      });
      _pendingSub = repository.onReplyPendingApprovalPayload.listen((payload) {
        final activeId = _activeTicketId;
        final payloadTicketId = payload['ticket']?['id'] as String?;
        final messageJson = payload['message'];
        if (activeId == null ||
            payloadTicketId != activeId ||
            messageJson is! Map<String, dynamic>) {
          return;
        }
        final msg = StaffTicketMessageDto.fromJson(messageJson);
        if (state.messages.any((m) => m.id == msg.id)) return;
        emit(state.copyWith(messages: [...state.messages, msg]));
      });
      _reviewedSub = repository.onReplyReviewedPayload.listen((payload) {
        final activeId = _activeTicketId;
        final payloadTicketId =
            (payload['ticket']?['id'] ?? payload['ticketId']) as String?;
        final messageJson = payload['message'];
        if (activeId == null ||
            payloadTicketId != activeId ||
            messageJson is! Map<String, dynamic>) {
          return;
        }
        final updated = StaffTicketMessageDto.fromJson(messageJson);
        final messages = state.messages
            .map((m) => m.id == updated.id ? updated : m)
            .toList();
        if (payload['status'] == 'APPROVED' &&
            !messages.any((m) => m.id == updated.id)) {
          messages.add(updated);
        }
        emit(state.copyWith(messages: messages));
      });
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Failed to load ticket. Tap retry.',
      ));
    }
  }

  Future<void> reload() async {
    final id = _activeTicketId;
    if (id != null) await load(id);
  }

  Future<void> leave() async {
    final id = _activeTicketId;
    if (id != null) await repository.leaveTicket(id);
    await _sub?.cancel();
    await _pendingSub?.cancel();
    await _reviewedSub?.cancel();
    await _connectSub?.cancel();
    await _disconnectSub?.cancel();
    _sub = null;
    _pendingSub = null;
    _reviewedSub = null;
    _activeTicketId = null;
  }

  Future<void> sendMedia({
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
  }) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    emit(state.copyWith(sending: true, clearActionError: true));
    try {
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: messageType,
        content: content,
        mediaMetadata: mediaMetadata,
      );
      if (!state.messages.any((m) => m.id == msg.id)) {
        emit(state.copyWith(
          messages: [...state.messages, msg],
          sending: false,
        ));
      } else {
        emit(state.copyWith(sending: false));
      }
    } catch (e) {
      emit(state.copyWith(
        sending: false,
        actionError: 'Failed to send attachment.',
      ));
    }
  }

  Future<void> sendMessage(String content) async {
    final ticket = state.ticket;
    if (ticket == null || content.trim().isEmpty) return;
    emit(state.copyWith(sending: true, clearActionError: true));
    try {
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: 'TEXT',
        content: content.trim(),
      );
      if (!state.messages.any((m) => m.id == msg.id)) {
        emit(state.copyWith(
          messages: [...state.messages, msg],
          sending: false,
        ));
      } else {
        emit(state.copyWith(sending: false));
      }
    } catch (e) {
      emit(state.copyWith(
        sending: false,
        actionError: 'Failed to send reply.',
      ));
    }
  }

  Future<void> claim() async {
    final ticket = state.ticket;
    if (ticket == null) return;
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      final updated = await repository.claimTicket(ticket.id);
      emit(state.copyWith(ticket: updated, actionLoading: false));
    } catch (e) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Could not claim ticket.',
      ));
    }
  }

  Future<void> transfer(String targetUserId) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      final updated = await repository.transferTicket(ticket.id, targetUserId);
      emit(state.copyWith(ticket: updated, actionLoading: false));
    } catch (e) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Transfer failed.',
      ));
    }
  }

  Future<void> forward(String targetUserId) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      final updated = await repository.forwardTicket(ticket.id, targetUserId);
      emit(state.copyWith(ticket: updated, actionLoading: false));
    } catch (e) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Forward failed.',
      ));
    }
  }

  Future<void> closeTicket({String? note}) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      final updated = await repository.closeTicket(ticket.id, note: note);
      emit(state.copyWith(ticket: updated, actionLoading: false));
    } catch (e) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Failed to close ticket.',
      ));
    }
  }

  Future<void> reviewMessage({
    required String messageId,
    required String status,
    String? comment,
  }) async {
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      final updated = await repository.reviewMessage(
        messageId: messageId,
        status: status,
        comment: comment,
      );
      final messages = state.messages.map((m) {
        return m.id == messageId ? updated : m;
      }).toList();
      emit(state.copyWith(messages: messages, actionLoading: false));
    } catch (e) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Review failed.',
      ));
    }
  }

  @override
  Future<void> close() async {
    await leave();
    return super.close();
  }
}
