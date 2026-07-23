import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../injection_container.dart';
import '../../../../chat/domain/entities/chat_message.dart';
import '../../../domain/entities/support_ticket.dart';
import '../../../domain/entities/ticket_message.dart';
import '../../../presentation/utils/ticket_thread_presence.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../../data/models/staff_support_ticket_dto.dart';
import '../../domain/repositories/staff_support_ticket_repository.dart';
import 'staff_ticket_queue_bloc.dart';

class StaffTicketThreadState {
  final StaffSupportTicket? ticket;
  final List<TicketMessage> messages;
  final bool loading;
  final bool sending;
  final bool actionLoading;
  final bool parentTyping;
  final String? error;
  final String? actionError;

  const StaffTicketThreadState({
    this.ticket,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.actionLoading = false,
    this.parentTyping = false,
    this.error,
    this.actionError,
  });

  StaffTicketThreadState copyWith({
    StaffSupportTicket? ticket,
    List<TicketMessage>? messages,
    bool? loading,
    bool? sending,
    bool? actionLoading,
    bool? parentTyping,
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
        parentTyping: parentTyping ?? this.parentTyping,
        error: clearError ? null : (error ?? this.error),
        actionError: clearActionError ? null : (actionError ?? this.actionError),
      );
}

class StaffTicketThreadCubit extends Cubit<StaffTicketThreadState> {
  final StaffSupportTicketRepository repository;
  StreamSubscription<TicketMessage>? _sub;
  StreamSubscription<Map<String, dynamic>>? _pendingSub;
  StreamSubscription<Map<String, dynamic>>? _reviewedSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<Map<String, dynamic>>? _closedSub;
  StreamSubscription<void>? _connectSub;
  Timer? _typingIdleTimer;
  Timer? _parentTypingClearTimer;
  String? _activeTicketId;
  bool _resyncing = false;

  StaffTicketThreadCubit({required this.repository})
      : super(const StaffTicketThreadState());

  Future<void> _resyncAfterReconnect(String ticketId) async {
    if (_resyncing || isClosed || _activeTicketId != ticketId) return;
    _resyncing = true;
    try {
      await repository.enterTicket(ticketId);
      final detail = await repository.fetchDetail(ticketId);
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
      InjectionContainer.staffTicketQueueBloc.add(
        StaffQueueUnreadCleared(ticketId),
      );
    } catch (_) {
    } finally {
      _resyncing = false;
    }
  }

  Future<void> load(String ticketId) async {
    _activeTicketId = ticketId;
    TicketThreadPresence.activeTicketId = ticketId;
    await _sub?.cancel();
    await _pendingSub?.cancel();
    await _reviewedSub?.cancel();
    await _typingSub?.cancel();
    await _readSub?.cancel();
    await _closedSub?.cancel();
    await _connectSub?.cancel();
    _parentTypingClearTimer?.cancel();
    emit(state.copyWith(
      loading: true,
      parentTyping: false,
      clearError: true,
      clearActionError: true,
    ));

    _sub = repository.onTicketMessage.listen(
      (msg) {
        if (_activeTicketId != ticketId) return;
        if (msg.ticketId != ticketId) return;
        if (state.messages.any((m) => m.id == msg.id)) return;
        emit(state.copyWith(
          messages: [...state.messages, msg],
          parentTyping: false,
        ));
        // Already viewing — clear unread so queue badge stays clean on back.
        if (msg.senderType == TicketMessageSenderType.guardian) {
          unawaited(repository.markRead(ticketId));
          InjectionContainer.staffTicketQueueBloc.add(
            StaffQueueUnreadCleared(ticketId),
          );
        }
      },
      onError: (Object e, StackTrace st) {
        print('StaffTicketThreadCubit message stream error: $e');
      },
      cancelOnError: false,
    );
    _pendingSub = repository.onReplyPendingApprovalPayload.listen(
      (payload) {
        final activeId = _activeTicketId;
        final payloadTicketId = payload['ticket']?['id'] as String?;
        final messageJson = payload['message'];
        if (activeId == null ||
            payloadTicketId != activeId ||
            messageJson is! Map) {
          return;
        }
        final msg = StaffTicketMessageDto.fromJson(
          Map<String, dynamic>.from(messageJson),
        );
        if (state.messages.any((m) => m.id == msg.id)) return;
        emit(state.copyWith(messages: [...state.messages, msg]));
      },
      onError: (_) {},
      cancelOnError: false,
    );
    _reviewedSub = repository.onReplyReviewedPayload.listen(
      (payload) {
        final activeId = _activeTicketId;
        final payloadTicketId =
            (payload['ticket']?['id'] ?? payload['ticketId']) as String?;
        final rawMessage = payload['message'];
        if (activeId == null ||
            payloadTicketId != activeId ||
            rawMessage is! Map) {
          return;
        }
        final messageJson = Map<String, dynamic>.from(rawMessage);
        if (messageJson['review_comment'] == null &&
            payload['reviewComment'] != null) {
          messageJson['review_comment'] = payload['reviewComment'];
        }
        if (messageJson['ticket_id'] == null) {
          messageJson['ticket_id'] = payloadTicketId;
        }
        final updated = StaffTicketMessageDto.fromJson(messageJson);
        final messages = state.messages
            .map((m) => m.id == updated.id ? updated : m)
            .toList();
        if ((payload['status'] == 'APPROVED' ||
                updated.reviewStatus == TicketMessageReviewStatus.approved) &&
            !messages.any((m) => m.id == updated.id)) {
          messages.add(updated);
        }
        emit(state.copyWith(messages: messages, parentTyping: false));
      },
      onError: (_) {},
      cancelOnError: false,
    );
    _typingSub = repository.onTicketTyping.listen(
      (payload) {
        if (payload['ticketId'] != ticketId) return;
        if (payload['userType'] != 'PARENT') return;
        final isTyping = payload['isTyping'] == true;
        emit(state.copyWith(parentTyping: isTyping));
        _parentTypingClearTimer?.cancel();
        if (isTyping) {
          _parentTypingClearTimer = Timer(const Duration(seconds: 3), () {
            if (!isClosed) emit(state.copyWith(parentTyping: false));
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
        // Parent read staff messages → blue ticks on our outgoing
        final by = payload['by']?.toString().toUpperCase();
        if (by != 'PARENT') return;
        if (isClosed) return;
        emit(state.copyWith(
          messages: state.messages
              .map((m) => m.senderType == TicketMessageSenderType.staff
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
    _closedSub = repository.onTicketClosed.listen(
      (payload) {
        if (_activeTicketId != ticketId) return;
        final closedId = payload['ticket']?['id']?.toString() ??
            payload['ticketId']?.toString();
        if (closedId != ticketId) return;
        final current = state.ticket;
        if (current == null || isClosed) return;
        emit(state.copyWith(
          ticket: current.copyWith(status: TicketStatus.closed),
          parentTyping: false,
        ));
      },
      onError: (_) {},
      cancelOnError: false,
    );

    try {
      await repository.connectSocket();
      await repository.enterTicket(ticketId);
      await repository.markRead(ticketId);
      InjectionContainer.staffTicketQueueBloc.add(
        StaffQueueUnreadCleared(ticketId),
      );
      final detail = await repository.fetchDetail(ticketId);
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

      emit(StaffTicketThreadState(
        ticket: detail.ticket,
        messages: merged,
        loading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Failed to load ticket. Tap retry.',
      ));
    }
  }

  void onComposerChanged(String text) {
    final ticket = state.ticket;
    if (ticket == null) return;
    if (text.trim().isNotEmpty) {
      repository.emitTicketTyping(ticketId: ticket.id, isTyping: true);
    }
    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(const Duration(milliseconds: 1800), () {
      repository.emitTicketTyping(ticketId: ticket.id, isTyping: false);
    });
  }

  Future<void> reload() async {
    final id = _activeTicketId;
    if (id != null) await load(id);
  }

  Future<void> leave() async {
    final id = _activeTicketId;
    if (id != null) {
      repository.emitTicketTyping(ticketId: id, isTyping: false);
      await repository.leaveTicket(id);
    }
    if (TicketThreadPresence.activeTicketId == id) {
      TicketThreadPresence.activeTicketId = null;
    }
    _typingIdleTimer?.cancel();
    _parentTypingClearTimer?.cancel();
    await _sub?.cancel();
    await _pendingSub?.cancel();
    await _reviewedSub?.cancel();
    await _typingSub?.cancel();
    await _readSub?.cancel();
    await _closedSub?.cancel();
    await _connectSub?.cancel();
    _sub = null;
    _pendingSub = null;
    _reviewedSub = null;
    _typingSub = null;
    _readSub = null;
    _closedSub = null;
    _connectSub = null;
    _activeTicketId = null;
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
        'senderName': replyTo.senderName ?? 'Message',
        if (replyUrl != null && replyUrl.isNotEmpty) 'url': replyUrl,
      },
    };
  }

  Future<void> sendMedia({
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
    ChatMessage? replyTo,
  }) async {
    final ticket = state.ticket;
    if (ticket == null) return;
    repository.emitTicketTyping(ticketId: ticket.id, isTyping: false);
    emit(state.copyWith(sending: true, clearActionError: true));
    try {
      final replyMeta = _replyMetadata(replyTo);
      final merged = <String, dynamic>{
        ...?mediaMetadata,
        ...replyMeta,
      };
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: messageType,
        content: content,
        mediaMetadata: merged.isEmpty ? null : merged,
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

  Future<void> sendMessage(String content, {ChatMessage? replyTo}) async {
    final ticket = state.ticket;
    if (ticket == null || content.trim().isEmpty) return;
    repository.emitTicketTyping(ticketId: ticket.id, isTyping: false);
    emit(state.copyWith(sending: true, clearActionError: true));
    try {
      final replyMeta = _replyMetadata(replyTo);
      final msg = await repository.sendMessage(
        ticketId: ticket.id,
        messageType: 'TEXT',
        content: content.trim(),
        mediaMetadata: replyMeta.isEmpty ? null : replyMeta,
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
