import '../../domain/entities/origination_options.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';

class SupportTicketDto {
  static SupportTicket fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      familyId: json['family_id'] as int,
      category: (json['category'] as String).toLowerCase() == 'financial'
          ? TicketCategory.financial
          : TicketCategory.general,
      subtopic: json['subtopic'] as String?,
      description: json['description'] as String,
      status: _status(json['status'] as String),
      lastMessageSnippet: json['last_message_snippet'] as String?,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      unreadByParent: json['unread_by_parent'] as int? ?? 0,
      studentName: json['students']?['full_name'] as String?,
      campusName: json['students']?['campuses']?['campus_name'] as String?,
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

class TicketMessageDto {
  static TicketMessage fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderType: (json['sender_type'] as String) == 'STAFF'
          ? TicketMessageSenderType.staff
          : TicketMessageSenderType.guardian,
      messageType: _type(json['message_type'] as String),
      content: json['content'] as String,
      reviewStatus: _review(json['status'] as String? ?? 'APPROVED'),
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender_user']?['full_name'] as String? ??
          json['sender_guardian']?['full_name'] as String?,
      senderRole: json['sender_user']?['role'] as String?,
      mediaMetadata: json['media_metadata'] as Map<String, dynamic>?,
    );
  }

  static TicketMessageType _type(String raw) {
    switch (raw) {
      case 'IMAGE':
        return TicketMessageType.image;
      case 'VOICE':
        return TicketMessageType.voice;
      case 'DOCUMENT':
        return TicketMessageType.document;
      default:
        return TicketMessageType.text;
    }
  }

  static TicketMessageReviewStatus _review(String raw) {
    switch (raw) {
      case 'PENDING':
        return TicketMessageReviewStatus.pending;
      case 'REJECTED':
        return TicketMessageReviewStatus.rejected;
      default:
        return TicketMessageReviewStatus.approved;
    }
  }
}

class OriginationOptionsDto {
  static OriginationOptions fromJson(Map<String, dynamic> json) {
    final topics = json['topics'] as Map<String, dynamic>;
    final childOpts = json['childOptions'] as Map<String, dynamic>;
    return OriginationOptions(
      categories: (json['categories'] as List)
          .map((c) => {
                'value': (c['value'] as String),
                'label': (c['label'] as String),
              })
          .toList(),
      topicsGeneralWithChild: (topics['GENERAL_WITH_CHILD'] as List)
          .map((e) => e.toString())
          .toList(),
      topicsGeneralNoChild: (topics['GENERAL_NO_CHILD'] as List)
          .map((e) => e.toString())
          .toList(),
      topicsFinancial:
          (topics['FINANCIAL'] as List).map((e) => e.toString()).toList(),
      generalNoChildLabel: childOpts['GENERAL_NO_CHILD_LABEL'] as String,
      financialFamilyLabel: childOpts['FINANCIAL_FAMILY_LABEL'] as String,
    );
  }
}
