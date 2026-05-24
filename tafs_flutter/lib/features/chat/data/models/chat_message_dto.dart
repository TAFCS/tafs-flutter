import '../../domain/entities/chat_message.dart';

class ChatMessageDto extends ChatMessage {
  const ChatMessageDto({
    required super.id,
    required super.conversationId,
    required super.senderType,
    super.senderId,
    super.senderName,
    required super.messageType,
    required super.content,
    super.mediaMetadata,
    required super.isRead,
    required super.createdAt,
    super.isAnnouncement,
    super.requiresAcknowledgment,
    super.isAcknowledged,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderType: _parseSenderType(json['sender_type'] as String),
      senderId: json['sender_id'] as String?,
      senderName: json['sender_name'] as String?,
      messageType: _parseMessageType(json['message_type'] as String),
      content: json['content'] as String,
      mediaMetadata: json['media_metadata'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      isAnnouncement: json['is_announcement'] as bool? ?? false,
      requiresAcknowledgment: json['requires_acknowledgment'] as bool? ?? false,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_type': senderType.name.toUpperCase(),
      'sender_id': senderId,
      'sender_name': senderName,
      'message_type': messageType.name.toUpperCase(),
      'content': content,
      'media_metadata': mediaMetadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'is_announcement': isAnnouncement,
    };
  }

  static ChatSenderType _parseSenderType(String type) {
    switch (type.toUpperCase()) {
      case 'ADMIN':
        return ChatSenderType.admin;
      case 'GUARDIAN':
      default:
        return ChatSenderType.guardian;
    }
  }

  static ChatMessageType _parseMessageType(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return ChatMessageType.image;
      case 'VOICE':
        return ChatMessageType.voice;
      case 'DOCUMENT':
        return ChatMessageType.document;
      case 'TEXT':
      default:
        return ChatMessageType.text;
    }
  }
}
