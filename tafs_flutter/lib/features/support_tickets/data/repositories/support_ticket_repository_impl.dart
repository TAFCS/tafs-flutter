import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
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
      chatRepository.onTicketMessagePayload
          .map(TicketMessageDto.tryFromPayload)
          .where((msg) => msg != null)
          .cast<TicketMessage>();

  @override
  Stream<Map<String, dynamic>> get onTicketTyping =>
      chatRepository.onTicketTyping;

  @override
  Stream<void> get onSocketConnect => chatRepository.onConnect;

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

  String _mimeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'webm':
        return 'audio/webm';
      case 'opus':
        return 'audio/ogg; codecs=opus';
      case 'm4a':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'ogg':
        return 'audio/ogg';
      case 'wav':
        return 'audio/wav';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Future<Map<String, dynamic>> uploadMedia(XFile file) async {
    MultipartFile multipartFile;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'upload';
      final mime = file.mimeType ?? _mimeFromFilename(filename);
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(mime),
      );
    } else {
      multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.name.isNotEmpty ? file.name : file.path.split('/').last,
      );
    }
    final form = FormData.fromMap({'file': multipartFile});
    final res = await dio.post('/support-tickets/media', data: form);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data['data'] ?? data);
    }
    return Map<String, dynamic>.from(data as Map);
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
    if (!chatRepository.isConnected) {
      for (var i = 0; i < 20 && !chatRepository.isConnected; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    chatRepository.enterTicket(ticketId);
  }

  @override
  Future<void> leaveTicket(String ticketId) async {
    chatRepository.leaveTicket(ticketId);
  }

  @override
  void emitTicketTyping({required String ticketId, required bool isTyping}) {
    chatRepository.emitTicketTyping(ticketId: ticketId, isTyping: isTyping);
  }
}
