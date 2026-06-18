enum TicketMessageSenderType { guardian, staff }

enum TicketMessageReviewStatus { pending, approved, rejected }

enum TicketMessageType { text, image, voice, document }

class TicketMessage {
  final String id;
  final String ticketId;
  final TicketMessageSenderType senderType;
  final TicketMessageType messageType;
  final String content;
  final TicketMessageReviewStatus reviewStatus;
  final DateTime createdAt;
  final String? senderName;
  final String? senderRole;
  final Map<String, dynamic>? mediaMetadata;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderType,
    required this.messageType,
    required this.content,
    required this.reviewStatus,
    required this.createdAt,
    this.senderName,
    this.senderRole,
    this.mediaMetadata,
  });
}
