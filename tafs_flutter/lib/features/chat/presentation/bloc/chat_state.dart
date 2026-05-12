import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool hasReachedMax;
  final int unreadCount;

  const ChatLoaded({
    required this.messages,
    this.hasReachedMax = false,
    this.unreadCount = 0,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasReachedMax,
    int? unreadCount,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMax, unreadCount];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
