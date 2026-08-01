class TicketEvent {
  final int id;
  final String eventType;
  final String? note;
  final DateTime createdAt;
  final String? actorName;
  final String? toUserName;

  const TicketEvent({
    required this.id,
    required this.eventType,
    this.note,
    required this.createdAt,
    this.actorName,
    this.toUserName,
  });

  String get label {
    switch (eventType) {
      case 'CREATED':
        return 'Ticket opened';
      case 'CLAIMED':
        return 'Claimed';
      case 'TRANSFERRED':
        return 'Transferred';
      case 'FORWARDED':
        return 'Forwarded';
      case 'REPLY_SUBMITTED':
        return 'Reply submitted for review';
      case 'REPLY_APPROVED':
        return 'Reply approved';
      case 'REPLY_REJECTED':
        return 'Reply rejected';
      case 'CLOSED_BY_STAFF':
        return 'Closed by staff';
      case 'CLOSED_BY_PARENT':
        return 'Closed by parent';
      default:
        return eventType;
    }
  }

  bool get isCloseEvent =>
      eventType == 'CLOSED_BY_STAFF' || eventType == 'CLOSED_BY_PARENT';
}
