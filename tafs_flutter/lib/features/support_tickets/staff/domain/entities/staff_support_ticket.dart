import '../../../domain/entities/support_ticket.dart';

class StaffSupportTicket {
  final String id;
  final int familyId;
  final TicketCategory category;
  final String? subtopic;
  final String description;
  final TicketStatus status;
  final String routedRole;
  final String? currentAssigneeId;
  final String? lastMessageSnippet;
  final DateTime lastMessageAt;
  final int unreadByStaff;
  final String? householdName;
  final String? studentName;
  final String? campusName;
  final String? assigneeName;
  final String? assigneeRole;

  const StaffSupportTicket({
    required this.id,
    required this.familyId,
    required this.category,
    this.subtopic,
    required this.description,
    required this.status,
    required this.routedRole,
    this.currentAssigneeId,
    this.lastMessageSnippet,
    required this.lastMessageAt,
    this.unreadByStaff = 0,
    this.householdName,
    this.studentName,
    this.campusName,
    this.assigneeName,
    this.assigneeRole,
  });
}

class PendingApproval {
  final String id;
  final String content;
  final String status;
  final DateTime createdAt;
  final String? senderName;
  final String? senderRole;
  final String? ticketId;
  final String? householdName;
  final String? subtopic;

  const PendingApproval({
    required this.id,
    required this.content,
    required this.status,
    required this.createdAt,
    this.senderName,
    this.senderRole,
    this.ticketId,
    this.householdName,
    this.subtopic,
  });
}

class StaffOption {
  final String id;
  final String fullName;
  final String username;
  final String role;

  const StaffOption({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
  });
}
