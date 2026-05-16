import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import 'dart:io';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {}

class ChatMessageReceived extends ChatEvent {
  final ChatMessage message;
  const ChatMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessagesRead extends ChatEvent {}

class ChatMessageSent extends ChatEvent {
  final String content;
  final ChatMessageType type;
  final File? file;
  final ChatMessage? replyTo;
  final Map<String, dynamic>? mediaMetadata;

  const ChatMessageSent({
    required this.content,
    required this.type,
    this.file,
    this.replyTo,
    this.mediaMetadata,
  });

  @override
  List<Object?> get props => [content, type, file, replyTo, mediaMetadata];
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

class ChatEntered extends ChatEvent {}

class ChatLeft extends ChatEvent {}

class ChatStudentsRequested extends ChatEvent {}
