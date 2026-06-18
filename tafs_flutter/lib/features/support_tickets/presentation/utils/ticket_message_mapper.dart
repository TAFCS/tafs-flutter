import '../../../chat/domain/entities/chat_message.dart';
import '../../domain/entities/ticket_message.dart';

bool isSuperAdminTicketMessage(TicketMessage message) =>
    message.senderRole == 'SUPER_ADMIN';

String staffTicketSenderLabel(TicketMessage message) {
  if (message.senderType != TicketMessageSenderType.staff) {
    return message.senderName ?? 'Parent';
  }
  final name = message.senderName ?? 'Staff';
  if (isSuperAdminTicketMessage(message)) {
    return '$name · Super Admin';
  }
  return name;
}

String parentTicketStaffSenderLabel(TicketMessage message) {
  if (isSuperAdminTicketMessage(message)) return 'TAFS Admin';
  return message.senderName ?? 'School';
}

ChatMessage ticketMessageToChatMessage(TicketMessage message) {
  ChatMessageType type;
  switch (message.messageType) {
    case TicketMessageType.image:
      type = ChatMessageType.image;
      break;
    case TicketMessageType.voice:
      type = ChatMessageType.voice;
      break;
    case TicketMessageType.document:
      type = ChatMessageType.document;
      break;
    default:
      type = ChatMessageType.text;
  }

  final mediaUrl = message.mediaMetadata?['url'] as String?;
  final content = type == ChatMessageType.text
      ? message.content
      : (mediaUrl ?? message.content);

  return ChatMessage(
    id: message.id,
    conversationId: message.ticketId,
    senderType: message.senderType == TicketMessageSenderType.guardian
        ? ChatSenderType.guardian
        : ChatSenderType.admin,
    senderName: message.senderType == TicketMessageSenderType.guardian
        ? (message.senderName ?? 'You')
        : parentTicketStaffSenderLabel(message),
    messageType: type,
    content: content,
    mediaMetadata: message.mediaMetadata,
    isRead: true,
    createdAt: message.createdAt,
    status: MessageStatus.sent,
  );
}
