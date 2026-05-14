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
    on<ChatEntered>(_onChatEntered);
    on<ChatLeft>(_onChatLeft);
    on<ChatStudentsRequested>(_onStudentsRequested);
  }

  bool isUserInChat = false;

  int _calculateUnread(List<ChatMessage> messages) {
    return messages.where((m) => !m.isRead && m.senderType == ChatSenderType.admin).length;
  }

  void _onChatEntered(ChatEntered event, Emitter<ChatState> emit) {
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

  void _onChatLeft(ChatLeft event, Emitter<ChatState> emit) {
    isUserInChat = false;
    repository.leaveChat();
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
      // Fetch students for tagging
      final students = await repository.getStudents();

      emit(ChatLoaded(
        messages: messages, 
        hasReachedMax: messages.length < 50,
        unreadCount: _calculateUnread(messages),
        students: students,
      ));
      // Only mark as read if we're starting IN the chat (unlikely for global start)
      if (isUserInChat) {
        repository.markAsRead();
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onMessageDeleted(ChatMessageDeleted event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = currentState.messages.where((m) => m.id != event.messageId).toList();
      emit(currentState.copyWith(
        messages: updatedMessages,
        unreadCount: _calculateUnread(updatedMessages),
      ));
    }
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;

      // Prevent duplicate: if a real message with this ID already exists, skip.
      if (currentState.messages.any((m) => m.id == event.message.id)) return;
      
      // Remove optimistic placeholder:
      final incomingTempId = event.message.mediaMetadata?['tempId'] as String?;
      
      final filteredMessages = currentState.messages.where((m) {
        if (m.status == MessageStatus.sending) {
          if (incomingTempId != null && m.id == incomingTempId) return false;
          if (incomingTempId == null && m.content == event.message.content && m.content.isNotEmpty) return false;
        }
        return true;
      }).toList();

      final updatedMessages = [event.message, ...filteredMessages];
      emit(currentState.copyWith(
        messages: updatedMessages,
        unreadCount: _calculateUnread(updatedMessages),
      ));
      
      // ONLY mark as read if we are actually in the chat screen
      if (isUserInChat) {
        repository.markAsRead();
      }
    }
  }

  void _onMessagesRead(ChatMessagesRead event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final List<ChatMessage> updatedMessages = currentState.messages.map<ChatMessage>((m) {
        // If someone (admin or another of our devices) read messages, update our UI
        return m.copyWith(isRead: true);
      }).toList();
      emit(currentState.copyWith(
        messages: updatedMessages,
        unreadCount: 0,
      ));
    }
  }

  Future<void> _onMessageSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create optimistic message
      final metadata = <String, dynamic>{};
      if (event.mediaMetadata != null) metadata.addAll(event.mediaMetadata!);
      if (event.file != null) metadata['localPath'] = event.file!.path;

      final optimisticMessage = ChatMessage(
        id: tempId,
        conversationId: currentState.messages.isNotEmpty ? currentState.messages.first.conversationId : '',
        senderType: ChatSenderType.guardian,
        messageType: event.type,
        content: event.content,
        mediaMetadata: metadata,
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

  Future<void> _onStudentsRequested(ChatStudentsRequested event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      try {
        final students = await repository.getStudents();
        emit(currentState.copyWith(students: students));
      } catch (e) {
        // Silent fail
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
