import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../chat/domain/entities/chat_message.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import '../utils/ticket_thread_presence.dart';

class TicketThreadState {
  final SupportTicket? ticket;
  final List<TicketMessage> messages;
  final bool loading;
  final bool sending;
  final bool staffTyping;
  final String? error;

  const TicketThreadState({
    this.ticket,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.staffTyping = false,
    this.error,
  });

  TicketThreadState copyWith({
    SupportTicket? ticket,
    List<TicketMessage>? messages,
    bool? loading,
    bool? sending,
    bool? staffTyping,
    String? error,
    bool clearError = false,
  }) =>
      TicketThreadState(
        ticket: ticket ?? this.ticket,
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        staffTyping: staffTyping ?? this.staffTyping,
        error: clearError ? null : (error ?? this.error),
      );
}

class TicketThreadCubit extends Cubit<TicketThreadState> {
  final SupportTicketRepository repository;
  StreamSubscription<TicketMessage>? _sub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<void>? _connectSub;
  Timer? _typingClearTimer;
  Timer? _typingIdleTimer;
  String? _activeTicketId;
  bool _resyncing = false;

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
    if (isClosed) return;
    if (state.messages.any((m) => m.id == msg.id)) return;
    emit(state.copyWith(
      messages: [...state.messages, msg],
      staffTyping: false,
      clearError: true,
    ));
  }

  Future<void> _resyncAfterReconnect(String ticketId) async {
    if (_resyncing || isClosed || _activeTicketId != ticketId) return;
    _resyncing = true;
    try {
      await repository.enterTicket(ticketId);
      final detail = await repository.getTicketDetail(ticketId);
      if (isClosed || _activeTicketId != ticketId) return;

      final byId = <String, TicketMessage>{
        for (final m in state.messages) m.id: m,
      };
      for (final m in detail.messages) {
        byId[m.id] = m;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      emit(state.copyWith(
        ticket: detail.ticket,
        messages: merged,
        clearError: true,
      ));
      await repository.markRead(ticketId);
    } catch (_) {
      // Soft resync — keep current UI.
    } finally {
      _resyncing = false;
    }
  }

  Map<String, dynamic> _replyMetadata(ChatMessage? replyTo) {
    if (replyTo == null) return {};
    final replyUrl = replyTo.mediaMetadata?['url'] as String? ??
        (replyTo.messageType == ChatMessageType.image ||
                replyTo.messageType == ChatMessageType.document ||
                replyTo.messageType == ChatMessageType.voice
            ? replyTo.content
            : null);
    return {
      'replyTo': {
        'id': replyTo.id,
        'content': replyTo.content,
        'type': replyTo.messageType.name.toUpperCase(),
        'senderName': replyTo.senderName ??
            (replyTo.senderType == ChatSenderType.guardian
                ? 'You'
                : 'TAFS Support'),
        if (replyUrl != null && replyUrl.isNotEmpty) 'url': replyUrl,
      },
    };
  }

  Future<void> load(String ticketId) async {
    _activeTicketId = ticketId;
    TicketThreadPresence.activeTicketId = ticketId;
    await _sub?.cancel();
    await _typingSub?.cancel();
    await _readSub?.cancel();
    await _connectSub?.cancel();
    _typingClearTimer?.cancel();
    emit(state.copyWith(loading: true, staffTyping: false, clearError: true));

    // Bind listeners first so socket events during REST load aren't dropped.
    _sub = repository.onTicketMessage.listen(
      (msg) {
        if (_activeTicketId != ticketId) return;
        if (msg.ticketId != ticketId) return;
        _appendMessage(msg);
      },
      onError: (Object e, StackTrace st) {
        print('TicketThreadCubit message stream error: $e');
      },
      cancelOnError: false,
    );
    _typingSub = repository.onTicketTyping.listen(
      (payload) {
        if (_activeTicketId != ticketId) return;
        final payloadTicketId =
            payload['ticketId']?.toString() ?? payload['ticket_id']?.toString();
        if (payloadTicketId != null &&
            payloadTicketId.isNotEmpty &&
            payloadTicketId != ticketId) {
          return;
        }
        final userType = payload['userType']?.toString().toUpperCase();
        if (userType != 'STAFF') return;
        final isTyping =
            payload['isTyping'] == true || payload['is_typing'] == true;
        if (isClosed) return;
        emit(state.copyWith(staffTyping: isTyping));
        _typingClearTimer?.cancel();
        if (isTyping) {
          _typingClearTimer = Timer(const Duration(seconds: 3), () {
            if (!isClosed) emit(state.copyWith(staffTyping: false));
          });
        }
      },
      onError: (_) {},
      cancelOnError: false,
    );
    _readSub = repository.onTicketMessagesRead.listen(
      (payload) {
        if (_activeTicketId != ticketId) return;
        final payloadTicketId = payload['ticketId']?.toString();
        if (payloadTicketId != null && payloadTicketId != ticketId) return;
        // Staff read our messages → blue double-ticks on parent outgoing
        final by = payload['by']?.toString().toUpperCase();
        if (by != 'STAFF') return;
        if (isClosed) return;
        emit(state.copyWith(
          messages: state.messages
              .map((m) => m.senderType == TicketMessageSenderType.guardian
                  ? m.copyWith(isRead: true)
                  : m)
              .toList(),
        ));
      },
      onError: (_) {},
      cancelOnError: false,
    );
    _connectSub = repository.onSocketConnect.listen((_) {
      unawaited(_resyncAfterReconnect(ticketId));
    });

    try {
      await repository.connectSocket();
      await repository.enterTicket(ticketId);
      await repository.markRead(ticketId);
      final detail = await repository.getTicketDetail(ticketId);
      if (isClosed || _activeTicketId != ticketId) return;

      final byId = <String, TicketMessage>{
        for (final m in state.messages)
          if (m.ticketId == ticketId) m.id: m,
      };
      for (final m in detail.messages) {
        byId[m.id] = m;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      emit(TicketThreadState(
        ticket: detail.ticket,
        messages: merged,
        loading: false,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: _friendlyError(e)));
    }
  }

  void onComposerChanged(String text) {
    final ticket = state.ticket;
    if (ticket == null) return;
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      repository.emitTicketTyping(ticketId: ticket.id, isTyping: true);
    }
    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(const Duration(milliseconds: 1800), () {
      repository.emitTicketTyping(ticketId: ticket.id, isTyping: false);
    });
  }

  Future<void> sendText(String content, {ChatMessage? replyTo}) async {
    final ticket = state.ticket;
    if (ticket == null || content.trim().isEmpty) return;
    repository.emitTicketTyping(ticketId: ticket.id, isTyping: false);
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final replyMeta = _replyMetadata(replyTo);
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: 'TEXT',
        content: content.trim(),
        mediaMetadata: replyMeta.isEmpty ? null : replyMeta,
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
    ChatMessage? replyTo,
  }) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    repository.emitTicketTyping(ticketId: ticket.id, isTyping: false);
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final mergedMetadata = {
        ...mediaMetadata,
        ..._replyMetadata(replyTo),
      };
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: messageType,
        content: content,
        mediaMetadata: mergedMetadata,
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
    if (id != null) {
      repository.emitTicketTyping(ticketId: id, isTyping: false);
      await repository.leaveTicket(id);
    }
    if (TicketThreadPresence.activeTicketId == id) {
      TicketThreadPresence.activeTicketId = null;
    }
    _typingClearTimer?.cancel();
    _typingIdleTimer?.cancel();
    await _sub?.cancel();
    await _typingSub?.cancel();
    await _readSub?.cancel();
    await _connectSub?.cancel();
    return super.close();
  }
}
