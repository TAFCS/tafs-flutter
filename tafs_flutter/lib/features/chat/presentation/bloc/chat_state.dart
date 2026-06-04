import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_student.dart';

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
  final List<ChatStudent> students;
  /// Count of messages fetched from the server via getChatHistory calls only.
  /// Used as the skip value for the next pagination request, so that optimistic
  /// or socket-pushed messages do not inflate the offset.
  final int serverMessageCount;
  final bool isSocketConnected;

  const ChatLoaded({
    required this.messages,
    this.hasReachedMax = false,
    this.unreadCount = 0,
    this.students = const [],
    this.serverMessageCount = 0,
    this.isSocketConnected = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasReachedMax,
    int? unreadCount,
    List<ChatStudent>? students,
    int? serverMessageCount,
    bool? isSocketConnected,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      unreadCount: unreadCount ?? this.unreadCount,
      students: students ?? this.students,
      serverMessageCount: serverMessageCount ?? this.serverMessageCount,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMax, unreadCount, students, serverMessageCount, isSocketConnected];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
