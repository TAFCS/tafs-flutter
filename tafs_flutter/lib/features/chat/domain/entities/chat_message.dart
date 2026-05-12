import 'package:equatable/equatable.dart';

enum ChatMessageType { text, image, voice, document }

enum ChatSenderType { guardian, admin }

enum MessageStatus { sending, sent, error }

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final ChatSenderType senderType;
  final String? senderId;
  final ChatMessageType messageType;
  final String content;
  final Map<String, dynamic>? mediaMetadata;
  final bool isRead;
  final DateTime createdAt;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    this.senderId,
    required this.messageType,
    required this.content,
    this.mediaMetadata,
    required this.isRead,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    ChatMessageType? messageType,
    Map<String, dynamic>? mediaMetadata,
    bool? isRead,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId,
      senderType: senderType,
      senderId: senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderType,
        senderId,
        messageType,
        content,
        mediaMetadata,
        isRead,
        createdAt,
        status,
      ];
}
