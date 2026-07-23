import '../entities/chat_message.dart';
import '../entities/chat_outbox_entry.dart';
import '../entities/chat_student.dart';
import 'package:image_picker/image_picker.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getChatHistory({int take = 50, int skip = 0});
  Future<String> uploadMedia(XFile file);
  void connect();
  void disconnect();
  bool get isConnected;
  Future<ChatMessage> sendMessage({
    required ChatMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
  });
  Future<void> enqueueOutbox(ChatOutboxEntry entry);
  Future<void> removeFromOutbox(String clientMessageId);
  Future<List<ChatOutboxEntry>> getPendingOutbox();
  Future<void> drainOutbox();
  Future<ChatMessage?> retryOutboxMessage(String clientMessageId);
  Future<List<ChatStudent>> getStudents();
  void markAsRead();
  void enterChat();
  void leaveChat();
  Future<void> acknowledgeMessage(String messageId);
  Stream<ChatMessage> get onMessageReceived;
  Stream<String> get onMessagesRead;
  Stream<String> get onMessageDeleted;
  Stream<void> get onConnect;
  Stream<void> get onDisconnect;
  Stream<void> get onSessionExpired;
  Stream<Map<String, dynamic>> get onTicketMessagePayload;
  Stream<Map<String, dynamic>> get onVoucherAlertPayload;
  Stream<Map<String, dynamic>> get onNoticeBoardPayload;
  Stream<Map<String, dynamic>> get onAttendanceAlertPayload;
  Stream<void> get onTicketQueueChanged;
  Stream<Map<String, dynamic>> get onTicketClosed;
  Stream<void> get onReplyPendingApproval;
  Stream<Map<String, dynamic>> get onReplyPendingApprovalPayload;
  Stream<Map<String, dynamic>> get onReplyReviewedPayload;
  void enterTicket(String ticketId);
  void leaveTicket(String ticketId);
  void emitTicketTyping({required String ticketId, required bool isTyping});
  Stream<Map<String, dynamic>> get onTicketTyping;
  Stream<Map<String, dynamic>> get onTicketMessagesRead;
  /// Ticket currently being viewed (if any). Rejoined automatically after reconnect.
  String? get activeTicketId;

  Future<List<ChatMessage>> getAdminAnnouncementHistory({
    int take = 50,
    int skip = 0,
  });

  void sendAnnouncement({
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
    String? targetGrade,
    String? targetSection,
  });

  Stream<ChatMessage> get onAnnouncementReceived;
}
