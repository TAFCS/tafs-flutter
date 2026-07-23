import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_outbox_entry.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/utils/chat_message_merge.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _readSubscription;
  StreamSubscription? _connectSubscription;
  StreamSubscription? _disconnectSubscription;
  StreamSubscription? _deleteSubscription;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<ChatSessionStartRequested>(_onChatStarted);
    on<ChatSessionStopRequested>(_onChatStopped);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMessagesRead>(_onMessagesRead);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatHistoryLoaded>(_onHistoryLoaded);
    on<ChatMessageDeleted>(_onMessageDeleted);
    on<ChatViewEntered>(_onChatEntered);
    on<ChatViewLeft>(_onChatLeft);
    on<ChatStudentsRequested>(_onStudentsRequested);
    on<ChatReconnectionSucceeded>(_onChatReconnected);
    on<ChatDisconnectionOccurred>(_onChatDisconnected);
    on<ChatMessageRetry>(_onMessageRetry);
    on<ChatMessageAcknowledged>(_onMessageAcknowledged);
  }

  bool isUserInChat = false;

  int _calculateUnread(List<ChatMessage> messages) {
    return messages.where((m) => !m.isRead && m.senderType == ChatSenderType.admin).length;
  }

  void _onChatEntered(ChatViewEntered event, Emitter<ChatState> emit) {
    isUserInChat = true;
    repository.enterChat();
    repository.markAsRead();

    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final List<ChatMessage> updatedMessages = currentState.messages.map<ChatMessage>((m) {
        if (m.senderType == ChatSenderType.admin) {
          return m.copyWith(isRead: true);
        }
        return m;
      }).toList();
      emit(currentState.copyWith(
        messages: updatedMessages,
        unreadCount: 0,
      ));
    }
  }

  void _onChatLeft(ChatViewLeft event, Emitter<ChatState> emit) {
    isUserInChat = false;
    repository.leaveChat();
  }

  Future<void> _onChatStarted(ChatSessionStartRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    repository.connect();

    _messageSubscription?.cancel();
    _messageSubscription = repository.onMessageReceived.listen((message) {
      add(ChatMessageReceived(message));
    });

    _readSubscription?.cancel();
    _readSubscription = repository.onMessagesRead.listen((by) {
      add(ChatMessagesRead(by));
    });

    _connectSubscription?.cancel();
    _connectSubscription = repository.onConnect.listen((_) {
      add(ChatReconnectionSucceeded());
    });

    _disconnectSubscription?.cancel();
    _disconnectSubscription = repository.onDisconnect.listen((_) {
      add(ChatDisconnectionOccurred());
    });

    _deleteSubscription?.cancel();
    _deleteSubscription = repository.onMessageDeleted.listen((messageId) {
      add(ChatMessageDeleted(messageId));
    });

    try {
      final messages = await repository.getChatHistory();
      final students = await repository.getStudents();
      final pendingOutbox = await repository.getPendingOutbox();
      final merged = _mergeOutboxIntoMessages(messages, pendingOutbox);

      emit(ChatLoaded(
        messages: merged,
        hasReachedMax: messages.length < 50,
        unreadCount: _calculateUnread(merged),
        students: students,
        serverMessageCount: messages.length,
        isSocketConnected: repository.isConnected,
      ));

      if (repository.isConnected) {
        await repository.drainOutbox();
      }

      if (isUserInChat) {
        repository.markAsRead();
      }
    } catch (e) {
      emit(ChatError(ApiErrorMapper.fromObject(
        e,
        fallback: 'Unable to load messages right now. Please try again.',
      )));
    }
  }

  List<ChatMessage> _mergeOutboxIntoMessages(
    List<ChatMessage> serverMessages,
    List<ChatOutboxEntry> outbox,
  ) {
    if (outbox.isEmpty) return serverMessages;

    final serverTempIds = serverMessages
        .map((m) => m.mediaMetadata?['tempId'] as String?)
        .whereType<String>()
        .toSet();

    final pending = outbox
        .where((e) => !serverTempIds.contains(e.clientMessageId))
        .map((e) => ChatMessage(
              id: e.clientMessageId,
              conversationId: serverMessages.isNotEmpty
                  ? serverMessages.first.conversationId
                  : '',
              senderType: ChatSenderType.guardian,
              messageType: _parseType(e.messageType),
              content: e.content,
              mediaMetadata: {
                ...?e.mediaMetadata,
                if (e.localFilePath != null) 'localPath': e.localFilePath,
              },
              isRead: false,
              createdAt: e.createdAt,
              status: MessageStatus.queued,
            ))
        .toList();

    final combined = [...pending, ...serverMessages];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  ChatMessageType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return ChatMessageType.image;
      case 'VOICE':
        return ChatMessageType.voice;
      case 'DOCUMENT':
        return ChatMessageType.document;
      default:
        return ChatMessageType.text;
    }
  }

  void _onChatDisconnected(ChatDisconnectionOccurred event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isSocketConnected: false));
    }
  }

  Future<void> _onChatReconnected(ChatReconnectionSucceeded event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    // Mark connected immediately so the UI updates before the history fetch.
    emit((state as ChatLoaded).copyWith(isSocketConnected: true));

    try {
      final serverRecent = await repository.getChatHistory(take: 50, skip: 0);
      final pendingOutbox = await repository.getPendingOutbox();

      if (state is! ChatLoaded) return;
      final currentLoaded = state as ChatLoaded;

      var merged = mergeChatMessagesWithServer(
        current: currentLoaded.messages,
        serverRecent: serverRecent,
      );
      merged = _mergeOutboxIntoMessages(merged, pendingOutbox);

      emit(currentLoaded.copyWith(
        messages: merged,
        unreadCount: _calculateUnread(merged),
        isSocketConnected: true,
      ));

      await repository.drainOutbox();
    } catch (e) {
      print('Chat reconnect sync failed: $e');
    }
  }

  void _onMessageDeleted(ChatMessageDeleted event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages =
          currentState.messages.where((m) => m.id != event.messageId).toList();
      emit(currentState.copyWith(
        messages: updatedMessages,
        unreadCount: _calculateUnread(updatedMessages),
      ));
    }
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;

      final incomingTempId = event.message.mediaMetadata?['tempId'] as String?;

      final filteredMessages = currentState.messages.where((m) {
        if (m.id == event.message.id) return false;
        if (m.status == MessageStatus.sending ||
            m.status == MessageStatus.queued ||
            (m.status == MessageStatus.error && m.id.startsWith('temp-'))) {
          if (incomingTempId != null && m.id == incomingTempId) return false;
          if (incomingTempId == null &&
              m.content == event.message.content &&
              m.content.isNotEmpty) {
            return false;
          }
        }
        return true;
      }).toList();

      final updatedMessages = [event.message, ...filteredMessages];
      emit(currentState.copyWith(
        messages: updatedMessages,
        unreadCount: _calculateUnread(updatedMessages),
      ));

      if (incomingTempId != null) {
        unawaited(repository.removeFromOutbox(incomingTempId));
      }

      if (isUserInChat) {
        repository.markAsRead();
      }
    }
  }

  void _onMessagesRead(ChatMessagesRead event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    // Only mark messages sent by the OTHER party as read.
    // 'ADMIN' marked as read → admin read the guardian's messages (blue tick on guardian messages).
    // 'GUARDIAN' marked as read → guardian read the admin's messages (blue tick on admin messages).
    final readSenderType = event.by == 'ADMIN'
        ? ChatSenderType.guardian
        : ChatSenderType.admin;

    final updatedMessages = currentState.messages.map<ChatMessage>((m) {
      return m.senderType == readSenderType ? m.copyWith(isRead: true) : m;
    }).toList();

    emit(currentState.copyWith(
      messages: updatedMessages,
      unreadCount: _calculateUnread(updatedMessages),
    ));
  }

  Future<void> _onMessageSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    final metadata = <String, dynamic>{};
    if (event.batchId != null) metadata['batchId'] = event.batchId;
    if (event.file != null) metadata['localPath'] = event.file!.path;

    if (event.replyTo != null) {
      final reply = event.replyTo!;
      final replyUrl = reply.mediaMetadata?['url'] as String? ??
          (reply.messageType == ChatMessageType.image ||
                  reply.messageType == ChatMessageType.document ||
                  reply.messageType == ChatMessageType.voice
              ? reply.content
              : null);
      metadata['replyTo'] = {
        'id': reply.id,
        'content': reply.content,
        'type': reply.messageType.name.toUpperCase(),
        'senderName': reply.senderName ??
            (reply.senderType == ChatSenderType.guardian
                ? 'You'
                : 'TAFS Support'),
        if (replyUrl != null && replyUrl.isNotEmpty) 'url': replyUrl,
      };
    }

    const initialStatus = MessageStatus.sending;

    final optimisticMessage = ChatMessage(
      id: tempId,
      conversationId: currentState.messages.isNotEmpty
          ? currentState.messages.first.conversationId
          : '',
      senderType: ChatSenderType.guardian,
      messageType: event.type,
      content: event.content,
      mediaMetadata: metadata,
      isRead: false,
      createdAt: DateTime.now(),
      status: initialStatus,
    );

    emit(currentState.copyWith(
      messages: [optimisticMessage, ...currentState.messages],
    ));

    // On web, XFile.path is a blob URL and not a real filesystem path.
    // We store it only on native so the outbox can re-upload on retry.
    final outboxMeta = <String, dynamic>{};
    if (event.batchId != null) outboxMeta['batchId'] = event.batchId;
    if (event.replyTo != null) {
      outboxMeta['replyToId'] = event.replyTo!.id;
      outboxMeta['replyTo'] = metadata['replyTo'];
    }

    final outboxEntry = ChatOutboxEntry(
      clientMessageId: tempId,
      messageType: event.type.name.toUpperCase(),
      content: event.content,
      localFilePath: (!kIsWeb && event.file != null) ? event.file!.path : null,
      mediaMetadata: outboxMeta.isEmpty ? null : outboxMeta,
      replyToId: event.replyTo?.id,
      createdAt: DateTime.now(),
    );
    await repository.enqueueOutbox(outboxEntry);

    try {
      String content = event.content;
      if (event.file != null) {
        if (state is! ChatLoaded) return;
        emit((state as ChatLoaded).copyWith(
          messages: (state as ChatLoaded).messages.map((m) {
            if (m.id == tempId) return m.copyWith(status: MessageStatus.sending);
            return m;
          }).toList(),
        ));
        content = await repository.uploadMedia(event.file!);
      }

      final finalMetadata = <String, dynamic>{'tempId': tempId};
      if (event.batchId != null) {
        finalMetadata['batchId'] = event.batchId;
      }
      if (event.replyTo != null) {
        finalMetadata['replyToId'] = event.replyTo!.id;
        finalMetadata['replyTo'] = metadata['replyTo'];
      }

      final confirmedMessage = await repository.sendMessage(
        type: event.type,
        content: content,
        metadata: finalMetadata,
      );

      if (state is! ChatLoaded) return;
      final successState = state as ChatLoaded;
      final updatedMessages = successState.messages.map((m) {
        if (m.id == tempId) return confirmedMessage;
        return m;
      }).toList();
      await repository.removeFromOutbox(tempId);
      emit(successState.copyWith(messages: updatedMessages));
    } catch (e) {
      if (state is! ChatLoaded) return;
      final errorState = state as ChatLoaded;
      final failedMessages = errorState.messages
          .map((m) =>
              m.id == tempId ? m.copyWith(status: MessageStatus.error) : m)
          .toList();
      emit(errorState.copyWith(messages: failedMessages));
    }
  }

  Future<void> _onMessageRetry(ChatMessageRetry event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;

    final updatedMessages = currentState.messages.map((m) {
      if (m.id == event.clientMessageId) {
        return m.copyWith(status: MessageStatus.sending);
      }
      return m;
    }).toList();
    emit(currentState.copyWith(messages: updatedMessages));

    final confirmed = await repository.retryOutboxMessage(event.clientMessageId);
    if (confirmed != null && state is ChatLoaded) {
      final afterState = state as ChatLoaded;
      final merged = afterState.messages.map((m) {
        if (m.id == event.clientMessageId) return confirmed;
        return m;
      }).toList();
      emit(afterState.copyWith(messages: merged));
    } else if (state is ChatLoaded) {
      final errorState = state as ChatLoaded;
      final failed = errorState.messages.map((m) {
        if (m.id == event.clientMessageId) {
          return m.copyWith(status: MessageStatus.error);
        }
        return m;
      }).toList();
      emit(errorState.copyWith(messages: failed));
    }
  }

  Future<void> _onHistoryLoaded(ChatHistoryLoaded event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    final currentState = state as ChatLoaded;
    if (currentState.hasReachedMax) return;

    try {
      final messages = await repository.getChatHistory(
        skip: currentState.serverMessageCount,
      );
      if (state is! ChatLoaded) return;
      final successState = state as ChatLoaded;
      if (messages.isEmpty) {
        emit(successState.copyWith(hasReachedMax: true));
      } else {
        emit(successState.copyWith(
          messages: mergeOlderMessagesIntoHistory(
            current: successState.messages,
            olderPage: messages,
          ),
          hasReachedMax: messages.length < 50,
          serverMessageCount: successState.serverMessageCount + messages.length,
        ));
      }
    } catch (_) {}
  }

  Future<void> _onStudentsRequested(
      ChatStudentsRequested event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    try {
      final students = await repository.getStudents();
      if (state is! ChatLoaded) return;
      emit((state as ChatLoaded).copyWith(students: students));
    } catch (_) {}
  }

  void _onChatStopped(ChatSessionStopRequested event, Emitter<ChatState> emit) {
    _messageSubscription?.cancel();
    _readSubscription?.cancel();
    _connectSubscription?.cancel();
    _disconnectSubscription?.cancel();
    _deleteSubscription?.cancel();
    repository.disconnect();
    emit(ChatInitial());
  }

  Future<void> _onMessageAcknowledged(
    ChatMessageAcknowledged event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistically update local state first
    if (state is ChatLoaded) {
      final current = state as ChatLoaded;
      final updated = current.messages.map((m) {
        return m.id == event.messageId ? m.copyWith(isAcknowledged: true) : m;
      }).toList();
      emit(current.copyWith(messages: updated));
    }
    // Fire-and-forget — ignore errors
    repository.acknowledgeMessage(event.messageId).catchError((_) {});
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _readSubscription?.cancel();
    _connectSubscription?.cancel();
    _disconnectSubscription?.cancel();
    _deleteSubscription?.cancel();
    repository.disconnect();
    return super.close();
  }
}
