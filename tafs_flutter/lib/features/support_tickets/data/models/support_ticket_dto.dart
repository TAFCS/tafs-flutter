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
    final ticketId = _asString(json['ticket_id']) ??
        _asString(json['ticketId']) ??
        '';
    final id = _asString(json['id']);
    if (id == null || id.isEmpty) {
      throw FormatException('Ticket message missing id');
    }
    return TicketMessage(
      id: id,
      ticketId: ticketId,
      senderType: (_asString(json['sender_type']) ?? '') == 'STAFF'
          ? TicketMessageSenderType.staff
          : TicketMessageSenderType.guardian,
      messageType: _type(_asString(json['message_type']) ?? 'TEXT'),
      content: _asString(json['content']) ?? '',
      reviewStatus: _review(_asString(json['status']) ?? 'APPROVED'),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      senderName: _asString(json['sender_user'] is Map
              ? (json['sender_user'] as Map)['full_name']
              : null) ??
          _asString(json['sender_guardian'] is Map
              ? (json['sender_guardian'] as Map)['full_name']
              : null),
      senderRole: json['sender_user'] is Map
          ? _asString((json['sender_user'] as Map)['role'])
          : null,
      senderUserId: json['sender_user'] is Map
          ? _asString((json['sender_user'] as Map)['id'])
          : null,
      mediaMetadata: json['media_metadata'] is Map
          ? Map<String, dynamic>.from(json['media_metadata'] as Map)
          : null,
      reviewComment: _asString(json['review_comment']),
      isRead: json['is_read'] == true || json['isRead'] == true,
    );
  }

  static TicketMessage? tryFromPayload(Map<String, dynamic> payload) {
    try {
      final rawMessage = payload['message'];
      if (rawMessage is! Map) return null;
      final message = Map<String, dynamic>.from(rawMessage);
      final ticket = payload['ticket'];
      if ((message['ticket_id'] == null || message['ticket_id'] == '') &&
          ticket is Map &&
          ticket['id'] != null) {
        message['ticket_id'] = ticket['id'].toString();
      }
      final parsed = fromJson(message);
      if (parsed.ticketId.isEmpty) return null;
      return parsed;
    } catch (e) {
      print('Error parsing ticket message payload: $e');
      return null;
    }
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      final ms = value > 9999999999 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.now();
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
