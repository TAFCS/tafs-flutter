import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/ticket_message.dart';
import '../entities/staff_support_ticket.dart';

abstract class StaffSupportTicketRepository {
  Stream<TicketMessage> get onTicketMessage;
  Stream<void> get onTicketQueueChanged;
  Stream<void> get onReplyPendingApproval;
  Stream<Map<String, dynamic>> get onReplyPendingApprovalPayload;
  Stream<Map<String, dynamic>> get onReplyReviewedPayload;
  bool get isSocketConnected;
  Stream<void> get onSocketConnect;
  Stream<void> get onSocketDisconnect;

  Future<void> connectSocket();
  Future<void> disconnectSocket();
  Future<void> enterTicket(String ticketId);
  Future<void> leaveTicket(String ticketId);

  Future<List<StaffSupportTicket>> fetchMyQueue();
  Future<List<StaffSupportTicket>> fetchFinanceQueue();
  Future<List<StaffSupportTicket>> fetchOversightQueue();
  Future<List<StaffSupportTicket>> fetchClosed();
  Future<({StaffSupportTicket ticket, List<TicketMessage> messages})> fetchDetail(
    String ticketId,
  );
  Future<List<PendingApproval>> fetchPendingApprovals();
  Future<List<StaffOption>> fetchStaffList();

  Future<TicketMessage> sendMessage({
    required String ticketId,
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
  });
  Future<void> markRead(String ticketId);
  Future<StaffSupportTicket> claimTicket(String ticketId);
  Future<StaffSupportTicket> transferTicket(String ticketId, String targetUserId);
  Future<StaffSupportTicket> forwardTicket(String ticketId, String targetUserId);
  Future<StaffSupportTicket> closeTicket(String ticketId, {String? note});
  Future<TicketMessage> reviewMessage({
    required String messageId,
    required String status,
    String? comment,
  });
  Future<Map<String, dynamic>> uploadMedia(XFile file);
}
