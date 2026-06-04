import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import 'package:image_picker/image_picker.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatSessionStartRequested extends ChatEvent {}

class ChatMessageReceived extends ChatEvent {
  final ChatMessage message;
  const ChatMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessagesRead extends ChatEvent {
  /// Who marked the messages as read: 'ADMIN' or 'GUARDIAN'.
  final String by;
  const ChatMessagesRead(this.by);

  @override
  List<Object?> get props => [by];
}

class ChatMessageSent extends ChatEvent {
  final String content;
  final ChatMessageType type;
  final XFile? file;
  final ChatMessage? replyTo;
  final String? batchId;

  const ChatMessageSent({
    required this.content,
    required this.type,
    this.file,
    this.replyTo,
    this.batchId,
  });

  @override
  List<Object?> get props => [content, type, file, replyTo, batchId];
}

class ChatHistoryLoaded extends ChatEvent {
  final int skip;
  const ChatHistoryLoaded({this.skip = 0});

  @override
  List<Object?> get props => [skip];
}

class ChatMessageDeleted extends ChatEvent {
  final String messageId;
  const ChatMessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ChatViewEntered extends ChatEvent {}

class ChatViewLeft extends ChatEvent {}

class ChatStudentsRequested extends ChatEvent {}

class ChatSessionStopRequested extends ChatEvent {}

class ChatReconnectionSucceeded extends ChatEvent {}

class ChatDisconnectionOccurred extends ChatEvent {}

class ChatMessageRetry extends ChatEvent {
  final String clientMessageId;
  const ChatMessageRetry(this.clientMessageId);

  @override
  List<Object?> get props => [clientMessageId];
}

class ChatMessageAcknowledged extends ChatEvent {
  final String messageId;
  const ChatMessageAcknowledged(this.messageId);

  @override
  List<Object?> get props => [messageId];
}
