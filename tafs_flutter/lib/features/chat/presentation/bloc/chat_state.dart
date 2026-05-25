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
  final List<Map<String, dynamic>> students;
  /// Count of messages fetched from the server via getChatHistory calls only.
  /// Used as the skip value for the next pagination request, so that optimistic
  /// or socket-pushed messages do not inflate the offset.
  final int serverMessageCount;

  const ChatLoaded({
    required this.messages,
    this.hasReachedMax = false,
    this.unreadCount = 0,
    this.students = const [],
    this.serverMessageCount = 0,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasReachedMax,
    int? unreadCount,
    List<Map<String, dynamic>>? students,
    int? serverMessageCount,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      unreadCount: unreadCount ?? this.unreadCount,
      students: students ?? this.students,
      serverMessageCount: serverMessageCount ?? this.serverMessageCount,
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMax, unreadCount, students, serverMessageCount];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
