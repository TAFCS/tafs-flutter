import 'package:equatable/equatable.dart';

enum ChatMessageType { text, image, voice, document }

enum ChatSenderType { guardian, admin }

enum MessageStatus { queued, sending, sent, error }

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final ChatSenderType senderType;
  final String? senderId;
  final String? senderName;
  final ChatMessageType messageType;
  final String content;
  final Map<String, dynamic>? mediaMetadata;
  final bool isRead;
  final DateTime createdAt;
  final MessageStatus status;
  final bool isAnnouncement;
  final bool requiresAcknowledgment;
  final bool isAcknowledged;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    this.senderId,
    this.senderName,
    required this.messageType,
    required this.content,
    this.mediaMetadata,
    required this.isRead,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.isAnnouncement = false,
    this.requiresAcknowledgment = false,
    this.isAcknowledged = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    ChatMessageType? messageType,
    Map<String, dynamic>? mediaMetadata,
    bool? isRead,
    MessageStatus? status,
    bool? isAnnouncement,
    String? senderName,
    bool? isAcknowledged,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId,
      senderType: senderType,
      senderId: senderId,
      senderName: senderName ?? this.senderName,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      status: status ?? this.status,
      isAnnouncement: isAnnouncement ?? this.isAnnouncement,
      requiresAcknowledgment: requiresAcknowledgment,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderType,
        senderId,
        senderName,
        messageType,
        content,
        mediaMetadata,
        isRead,
        createdAt,
        status,
        isAnnouncement,
        requiresAcknowledgment,
        isAcknowledged,
      ];
}
