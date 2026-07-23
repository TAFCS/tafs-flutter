import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/ticket_message.dart';
import '../../../../chat/domain/repositories/chat_repository.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../../domain/repositories/staff_support_ticket_repository.dart';
import '../models/staff_support_ticket_dto.dart';

class StaffSupportTicketRepositoryImpl implements StaffSupportTicketRepository {
  final Dio dio;
  final ChatRepository chatRepository;

  StaffSupportTicketRepositoryImpl({
    required this.dio,
    required this.chatRepository,
  });

  List<StaffSupportTicket> _parseList(dynamic data) {
    final items = (data is Map ? (data['items'] ?? data['data']?['items'] ?? data) : data) as List;
    return items
        .map((e) => StaffSupportTicketDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<TicketMessage> get onTicketMessage =>
      chatRepository.onTicketMessagePayload
          .map(StaffTicketMessageDto.tryFromPayload)
          .where((msg) => msg != null)
          .cast<TicketMessage>();

  @override
  Stream<void> get onTicketQueueChanged =>
      chatRepository.onTicketQueueChanged;

  @override
  Stream<void> get onReplyPendingApproval =>
      chatRepository.onReplyPendingApproval;

  @override
  Stream<Map<String, dynamic>> get onReplyPendingApprovalPayload =>
      chatRepository.onReplyPendingApprovalPayload;

  @override
  Stream<Map<String, dynamic>> get onReplyReviewedPayload =>
      chatRepository.onReplyReviewedPayload;

  @override
  Stream<Map<String, dynamic>> get onTicketTyping =>
      chatRepository.onTicketTyping;

  @override
  Stream<Map<String, dynamic>> get onTicketMessagesRead =>
      chatRepository.onTicketMessagesRead;

  @override
  bool get isSocketConnected => chatRepository.isConnected;

  @override
  Stream<void> get onSocketConnect => chatRepository.onConnect;

  @override
  Stream<void> get onSocketDisconnect => chatRepository.onDisconnect;

  @override
  Future<void> connectSocket() async {
    chatRepository.connect();
  }

  @override
  Future<void> disconnectSocket() async {
    chatRepository.disconnect();
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

  @override
  Future<List<StaffSupportTicket>> fetchMyQueue() async {
    final res = await dio.get('/support-tickets/my-queue');
    return _parseList(res.data);
  }

  @override
  Future<List<StaffSupportTicket>> fetchFinanceQueue() async {
    final res = await dio.get('/support-tickets/finance-queue');
    return _parseList(res.data);
  }

  @override
  Future<List<StaffSupportTicket>> fetchOversightQueue() async {
    final res = await dio.get('/support-tickets/oversight');
    return _parseList(res.data);
  }

  @override
  Future<List<StaffSupportTicket>> fetchClosed() async {
    final res = await dio.get('/support-tickets/closed');
    return _parseList(res.data);
  }

  @override
  Future<({StaffSupportTicket ticket, List<TicketMessage> messages})> fetchDetail(
    String ticketId,
  ) async {
    final res = await dio.get('/support-tickets/$ticketId');
    final data = (res.data is Map && res.data['data'] != null)
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final ticket = StaffSupportTicketDto.fromJson(data);
    final messages = (data['messages'] as List? ?? [])
        .map((m) => StaffTicketMessageDto.fromJson(m as Map<String, dynamic>))
        .toList();
    return (ticket: ticket, messages: messages);
  }

  @override
  Future<List<PendingApproval>> fetchPendingApprovals() async {
    final res = await dio.get('/support-tickets/approvals/pending');
    final data = res.data;
    final items = (data is Map ? (data['data'] ?? data['items'] ?? data) : data) as List;
    return items
        .map((e) => PendingApprovalDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StaffOption>> fetchStaffList() async {
    final res = await dio.get('/users');
    final list = (res.data is Map ? (res.data['data'] ?? res.data) : res.data) as List;
    return list
        .where((u) => (u as Map)['is_active'] != false)
        .map((u) => StaffOptionDto.fromJson(u as Map<String, dynamic>))
        .toList();
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
    final body = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StaffTicketMessageDto.fromJson(body);
  }

  @override
  Future<void> markRead(String ticketId) async {
    await dio.post('/support-tickets/mark-read', data: {'ticketId': ticketId});
  }

  @override
  Future<StaffSupportTicket> claimTicket(String ticketId) async {
    final res = await dio.post('/support-tickets/$ticketId/claim');
    final body = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StaffSupportTicketDto.fromJson(body);
  }

  @override
  Future<StaffSupportTicket> transferTicket(
    String ticketId,
    String targetUserId,
  ) async {
    final res = await dio.post('/support-tickets/$ticketId/transfer', data: {
      'targetUserId': targetUserId,
    });
    final body = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StaffSupportTicketDto.fromJson(body);
  }

  @override
  Future<StaffSupportTicket> forwardTicket(
    String ticketId,
    String targetUserId,
  ) async {
    final res = await dio.post('/support-tickets/$ticketId/forward', data: {
      'targetUserId': targetUserId,
    });
    final body = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StaffSupportTicketDto.fromJson(body);
  }

  @override
  Future<StaffSupportTicket> closeTicket(String ticketId, {String? note}) async {
    final res = await dio.post('/support-tickets/$ticketId/close', data: {
      if (note != null && note.isNotEmpty) 'note': note,
    });
    final body = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StaffSupportTicketDto.fromJson(body);
  }

  @override
  Future<TicketMessage> reviewMessage({
    required String messageId,
    required String status,
    String? comment,
  }) async {
    final res = await dio.patch('/support-tickets/messages/$messageId/review', data: {
      'status': status,
      if (comment != null) 'comment': comment,
    });
    final body = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StaffTicketMessageDto.fromJson(body);
  }

  String _mimeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'webm':
        return 'audio/webm';
      case 'm4a':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
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
}
