import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _readSubscription;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMessagesRead>(_onMessagesRead);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatHistoryLoaded>(_onHistoryLoaded);
    on<ChatMessageDeleted>(_onMessageDeleted);
  }

  Future<void> _onChatStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    repository.connect();
    
    _messageSubscription?.cancel();
    _messageSubscription = repository.onMessageReceived.listen((message) {
      add(ChatMessageReceived(message));
    });

    _readSubscription?.cancel();
    _readSubscription = repository.onMessagesRead.listen((_) {
      add(ChatMessagesRead());
    });

    repository.onMessageDeleted.listen((messageId) {
      add(ChatMessageDeleted(messageId));
    });

    try {
      final messages = await repository.getChatHistory();
      emit(ChatLoaded(messages: messages, hasReachedMax: messages.length < 50));
      repository.markAsRead();
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onMessageDeleted(ChatMessageDeleted event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = currentState.messages.where((m) => m.id != event.messageId).toList();
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Remove optimistic message if it matches the incoming one
      final filteredMessages = currentState.messages.where((m) {
        if (m.status == MessageStatus.sending && m.content == event.message.content) {
          return false;
        }
        return true;
      }).toList();

      final updatedMessages = [event.message, ...filteredMessages];
      emit(currentState.copyWith(messages: updatedMessages));
      repository.markAsRead();
    }
  }

  void _onMessagesRead(ChatMessagesRead event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = currentState.messages.map((m) {
        if (m.senderType == ChatSenderType.guardian) {
          return ChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            senderType: m.senderType,
            senderId: m.senderId,
            messageType: m.messageType,
            content: m.content,
            mediaMetadata: m.mediaMetadata,
            isRead: true,
            createdAt: m.createdAt,
          );
        }
        return m;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  Future<void> _onMessageSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create optimistic message
      final optimisticMessage = ChatMessage(
        id: tempId,
        conversationId: currentState.messages.isNotEmpty ? currentState.messages.first.conversationId : '',
        senderType: ChatSenderType.guardian,
        messageType: event.type,
        content: event.content,
        mediaMetadata: event.mediaMetadata,
        isRead: false,
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      );

      emit(currentState.copyWith(messages: [optimisticMessage, ...currentState.messages]));

      try {
        String content = event.content;
        if (event.file != null) {
          content = await repository.uploadMedia(event.file!);
        }
        
        final metadata = <String, dynamic>{'tempId': tempId};
        if (event.mediaMetadata != null) {
          metadata.addAll(event.mediaMetadata!);
        }

        repository.sendMessage(
          type: event.type,
          content: content,
          metadata: metadata,
        );
      } catch (e) {
        // Update status to error
        final errorState = state as ChatLoaded;
        final failedMessages = errorState.messages.map((m) => m.id == tempId ? m.copyWith(status: MessageStatus.error) : m).toList();
        emit(errorState.copyWith(messages: failedMessages));
      }
    }
  }

  Future<void> _onHistoryLoaded(ChatHistoryLoaded event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      if (currentState.hasReachedMax) return;

      try {
        final messages = await repository.getChatHistory(skip: currentState.messages.length);
        if (messages.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(ChatLoaded(
            messages: currentState.messages + messages,
            hasReachedMax: messages.length < 50,
          ));
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _readSubscription?.cancel();
    repository.disconnect();
    return super.close();
  }
}
