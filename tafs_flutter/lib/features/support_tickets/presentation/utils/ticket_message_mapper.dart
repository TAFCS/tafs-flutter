import '../../../chat/domain/entities/chat_message.dart';
import '../../domain/entities/ticket_message.dart';

bool isSuperAdminTicketMessage(TicketMessage message) =>
    message.senderRole == 'SUPER_ADMIN';

bool isOwnStaffMessage(TicketMessage message, String viewerStaffId) =>
    message.senderType == TicketMessageSenderType.staff &&
    message.senderUserId == viewerStaffId;

String staffViewMessageLabel(
  TicketMessage message, {
  required String viewerStaffId,
}) {
  if (message.senderType == TicketMessageSenderType.guardian) {
    return message.senderName != null
        ? 'Parent · ${message.senderName}'
        : 'Parent';
  }
  if (isOwnStaffMessage(message, viewerStaffId)) {
    return message.senderName ?? 'You';
  }
  if (isSuperAdminTicketMessage(message)) {
    return '${message.senderName ?? 'Staff'} · Super Admin';
  }
  final roleLabel = message.senderRole?.replaceAll('_', ' ') ?? 'Assignee';
  return '${message.senderName ?? 'Staff'} · $roleLabel';
}

String parentTicketStaffSenderLabel(TicketMessage message) {
  if (isSuperAdminTicketMessage(message)) return 'TAFS Admin';
  return message.senderName ?? 'School';
}

ChatMessageType _ticketMessageType(TicketMessage message) {
  switch (message.messageType) {
    case TicketMessageType.image:
      return ChatMessageType.image;
    case TicketMessageType.voice:
      return ChatMessageType.voice;
    case TicketMessageType.document:
      return ChatMessageType.document;
    default:
      return ChatMessageType.text;
  }
}

String _ticketMessageContent(TicketMessage message, ChatMessageType type) {
  final mediaUrl = message.mediaMetadata?['url'] as String?;
  return type == ChatMessageType.text
      ? message.content
      : (mediaUrl ?? message.content);
}

ChatMessage staffTicketMessageToChatMessage(
  TicketMessage message, {
  required String viewerStaffId,
}) {
  final type = _ticketMessageType(message);
  final isOutgoing = isOwnStaffMessage(message, viewerStaffId);

  return ChatMessage(
    id: message.id,
    conversationId: message.ticketId,
    senderType: isOutgoing ? ChatSenderType.guardian : ChatSenderType.admin,
    senderName: staffViewMessageLabel(message, viewerStaffId: viewerStaffId),
    messageType: type,
    content: _ticketMessageContent(message, type),
    mediaMetadata: message.mediaMetadata,
    isRead: message.isRead,
    createdAt: message.createdAt,
    status: MessageStatus.sent,
  );
}

ChatMessage ticketMessageToChatMessage(TicketMessage message) {
  final type = _ticketMessageType(message);

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
    content: _ticketMessageContent(message, type),
    mediaMetadata: message.mediaMetadata,
    isRead: message.isRead,
    createdAt: message.createdAt,
    status: MessageStatus.sent,
  );
}
