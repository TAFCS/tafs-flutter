import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/origination_options.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import '../models/support_ticket_dto.dart';
import '../../../chat/domain/repositories/chat_repository.dart';

class SupportTicketRepositoryImpl implements SupportTicketRepository {
  final Dio dio;
  final ChatRepository chatRepository;

  SupportTicketRepositoryImpl({
    required this.dio,
    required this.chatRepository,
  });

  @override
  Stream<TicketMessage> get onTicketMessage =>
      chatRepository.onTicketMessagePayload.map((payload) {
        final message = payload['message'] as Map<String, dynamic>;
        return TicketMessageDto.fromJson(message);
      });

  @override
  Future<OriginationOptions> getOriginationOptions() async {
    final res = await dio.get('/support-tickets/origination-options');
    return OriginationOptionsDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<SupportTicket>> listTickets({required bool open}) async {
    final res = await dio.get(
      '/support-tickets/mine',
      queryParameters: {'status': open ? 'open' : 'closed'},
    );
    final data = res.data;
    final items = (data['items'] ?? data) as List;
    return items
        .map((e) => SupportTicketDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SupportTicket> createTicket({
    required String category,
    int? studentId,
    required String subtopic,
    required String description,
    Map<String, dynamic>? mediaMetadata,
  }) async {
    final res = await dio.post('/support-tickets', data: {
      'category': category.toUpperCase(),
      if (studentId != null) 'studentId': studentId,
      'subtopic': subtopic,
      'description': description,
      if (mediaMetadata != null) 'mediaMetadata': mediaMetadata,
    });
    return SupportTicketDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<({SupportTicket ticket, List<TicketMessage> messages})> getTicketDetail(
    String ticketId,
  ) async {
    final res = await dio.get('/support-tickets/$ticketId');
    final data = res.data as Map<String, dynamic>;
    final ticket = SupportTicketDto.fromJson(data);
    final messages = (data['messages'] as List? ?? [])
        .map((m) => TicketMessageDto.fromJson(m as Map<String, dynamic>))
        .toList();
    return (ticket: ticket, messages: messages);
  }

  @override
  Future<TicketMessage> sendMessage({
    required String ticketId,
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
  }) async {
    final res = await dio.post('/support-tickets/$ticketId/messages', data: {
      'messageType': messageType.toUpperCase(),
      'content': content,
      if (mediaMetadata != null) 'mediaMetadata': mediaMetadata,
    });
    return TicketMessageDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> uploadMedia(XFile file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final res = await dio.post('/support-tickets/media', data: form);
    return Map<String, dynamic>.from(res.data as Map);
  }

  @override
  Future<void> closeTicket(String ticketId) async {
    await dio.post('/support-tickets/$ticketId/close', data: {});
  }

  @override
  Future<void> markRead(String ticketId) async {
    await dio.post('/support-tickets/mark-read', data: {'ticketId': ticketId});
  }

  @override
  Future<void> connectSocket() async {
    chatRepository.connect();
  }

  @override
  Future<void> enterTicket(String ticketId) async {
    chatRepository.connect();
    chatRepository.enterTicket(ticketId);
  }

  @override
  Future<void> leaveTicket(String ticketId) async {
    chatRepository.leaveTicket(ticketId);
  }
}
