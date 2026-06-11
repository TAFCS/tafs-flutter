import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/staff_announcements_repository.dart';
import '../models/grade_section_dto.dart';

class StaffAnnouncementsRepositoryImpl implements StaffAnnouncementsRepository {
  final Dio dio;
  final ChatRepository chatRepository;

  StaffAnnouncementsRepositoryImpl({
    required this.dio,
    required this.chatRepository,
  });

  @override
  bool get isSocketConnected => chatRepository.isConnected;

  @override
  Stream<ChatMessage> get onAnnouncementReceived =>
      chatRepository.onAnnouncementReceived;

  @override
  Stream<void> get onSocketConnect => chatRepository.onConnect;

  @override
  Stream<void> get onSocketDisconnect => chatRepository.onDisconnect;

  @override
  void ensureSocketConnected() => chatRepository.connect();

  @override
  Future<List<ChatMessage>> fetchHistory({int take = 50, int skip = 0}) {
    return chatRepository.getAdminAnnouncementHistory(take: take, skip: skip);
  }

  @override
  Future<List<GradeOption>> fetchGrades() async {
    final res = await dio.get('/classes');
    final data = res.data;
    final list = (data is Map ? (data['data'] ?? data) : data) as List;
    return list
        .map((e) => GradeOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SectionOption>> fetchSections() async {
    final res = await dio.get('/sections');
    final data = res.data;
    final list = (data is Map ? (data['data'] ?? data) : data) as List;
    return list
        .map((e) => SectionOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _mimeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'm4a':
        return 'audio/mp4';
      case 'webm':
        return 'audio/webm';
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
    final res = await dio.post('/chat/media', data: form);
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final inner = body['data'] ?? body;
      return Map<String, dynamic>.from(inner as Map);
    }
    return {'url': body.toString()};
  }

  @override
  void sendAnnouncement({
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
    String? targetGrade,
    String? targetSection,
  }) {
    chatRepository.sendAnnouncement(
      messageType: messageType,
      content: content,
      mediaMetadata: mediaMetadata,
      targetGrade: targetGrade,
      targetSection: targetSection,
    );
  }
}
