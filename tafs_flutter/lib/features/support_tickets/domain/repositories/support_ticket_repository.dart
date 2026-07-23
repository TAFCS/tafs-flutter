import '../entities/origination_options.dart';
import '../entities/support_ticket.dart';
import '../entities/ticket_message.dart';

import 'package:image_picker/image_picker.dart';

abstract class SupportTicketRepository {
  Future<OriginationOptions> getOriginationOptions();
  Future<List<SupportTicket>> listTickets({required bool open});
  Future<SupportTicket> createTicket({
    required String category,
    int? studentId,
    required String subtopic,
    required String description,
    Map<String, dynamic>? mediaMetadata,
  });
  Future<({SupportTicket ticket, List<TicketMessage> messages})> getTicketDetail(
    String ticketId,
  );
  Future<TicketMessage> sendMessage({
    required String ticketId,
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
  });
  Future<void> closeTicket(String ticketId);
  Future<void> markRead(String ticketId);
  Future<Map<String, dynamic>> uploadMedia(XFile file);
  Stream<TicketMessage> get onTicketMessage;
  Stream<Map<String, dynamic>> get onTicketTyping;
  Stream<Map<String, dynamic>> get onTicketMessagesRead;
  Stream<void> get onSocketConnect;
  Future<void> connectSocket();
  Future<void> enterTicket(String ticketId);
  Future<void> leaveTicket(String ticketId);
  void emitTicketTyping({required String ticketId, required bool isTyping});
}
