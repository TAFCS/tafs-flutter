import '../../../domain/entities/support_ticket.dart';
import '../../../domain/entities/ticket_message.dart';
import '../../../data/models/support_ticket_dto.dart';
import '../../domain/entities/staff_support_ticket.dart';

class StaffSupportTicketDto {
  static StaffSupportTicket fromJson(Map<String, dynamic> json) {
    final categoryRaw = (json['category'] as String).toUpperCase();
    return StaffSupportTicket(
      id: json['id'] as String,
      familyId: json['family_id'] as int,
      category: categoryRaw == 'FINANCIAL'
          ? TicketCategory.financial
          : TicketCategory.general,
      subtopic: json['subtopic'] as String?,
      description: json['description'] as String? ?? '',
      status: _status(json['status'] as String),
      routedRole: json['routed_role'] as String? ?? '',
      currentAssigneeId: json['current_assignee_id'] as String?,
      lastMessageSnippet: json['last_message_snippet'] as String?,
      lastFamilySnippet: json['last_family_snippet'] as String?,
      lastFamilySenderName: json['last_family_sender_name'] as String?,
      lastStaffSnippet: json['last_staff_snippet'] as String?,
      lastStaffSenderId: json['last_staff_sender_id'] as String?,
      lastStaffSenderName: json['last_staff_sender_name'] as String?,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      unreadByStaff: json['unread_by_staff'] as int? ?? 0,
      householdName: json['families']?['household_name'] as String?,
      studentName: json['students']?['full_name'] as String?,
      campusName: json['students']?['campuses']?['campus_name'] as String?,
      assigneeName: json['current_assignee']?['full_name'] as String?,
      assigneeRole: json['current_assignee']?['role'] as String?,
    );
  }

  static TicketStatus _status(String raw) {
    switch (raw) {
      case 'ASSIGNED':
        return TicketStatus.assigned;
      case 'CLOSED':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }
}

class PendingApprovalDto {
  static PendingApproval fromJson(Map<String, dynamic> json) {
    final ticket = json['ticket'] as Map<String, dynamic>?;
    return PendingApproval(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender_user']?['full_name'] as String?,
      senderRole: json['sender_user']?['role'] as String?,
      ticketId: ticket?['id'] as String?,
      householdName: ticket?['families']?['household_name'] as String?,
      subtopic: ticket?['subtopic'] as String?,
    );
  }
}

class StaffOptionDto {
  static StaffOption fromJson(Map<String, dynamic> json) {
    return StaffOption(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

class StaffTicketMessageDto {
  static TicketMessage fromJson(Map<String, dynamic> json) {
    return TicketMessageDto.fromJson(json);
  }

  static TicketMessage? tryFromPayload(Map<String, dynamic> payload) {
    return TicketMessageDto.tryFromPayload(payload);
  }
}
