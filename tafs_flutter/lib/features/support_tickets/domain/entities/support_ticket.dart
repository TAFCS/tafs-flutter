enum TicketCategory { general, financial }

enum TicketStatus { open, assigned, closed }

class SupportTicket {
  final String id;
  final int familyId;
  final TicketCategory category;
  final String? subtopic;
  final String description;
  final TicketStatus status;
  final String? lastMessageSnippet;
  final DateTime lastMessageAt;
  final int unreadByParent;
  final String? studentName;
  final String? campusName;

  const SupportTicket({
    required this.id,
    required this.familyId,
    required this.category,
    this.subtopic,
    required this.description,
    required this.status,
    this.lastMessageSnippet,
    required this.lastMessageAt,
    this.unreadByParent = 0,
    this.studentName,
    this.campusName,
  });

  SupportTicket copyWith({int? unreadByParent, TicketStatus? status}) {
    return SupportTicket(
      id: id,
      familyId: familyId,
      category: category,
      subtopic: subtopic,
      description: description,
      status: status ?? this.status,
      lastMessageSnippet: lastMessageSnippet,
      lastMessageAt: lastMessageAt,
      unreadByParent: unreadByParent ?? this.unreadByParent,
      studentName: studentName,
      campusName: campusName,
    );
  }
}
