import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/chat_message.dart';
import '../../data/models/grade_section_dto.dart';

abstract class StaffAnnouncementsRepository {
  bool get isSocketConnected;
  Stream<ChatMessage> get onAnnouncementReceived;
  Stream<void> get onSocketConnect;
  Stream<void> get onSocketDisconnect;

  void ensureSocketConnected();
  Future<List<ChatMessage>> fetchHistory({int take = 50, int skip = 0});
  Future<List<GradeOption>> fetchGrades();
  Future<List<SectionOption>> fetchSections();
  Future<Map<String, dynamic>> uploadMedia(XFile file);
  void sendAnnouncement({
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
    String? targetGrade,
    String? targetSection,
  });
}
