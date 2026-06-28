import 'package:dio/dio.dart';
import '../../domain/entities/employee_notice.dart';

class EmployeeNoticeRemoteDataSource {
  final Dio dio;

  EmployeeNoticeRemoteDataSource(this.dio);

  Future<List<EmployeeNotice>> getFeed() async {
    final response = await dio.get('/hr/employee-notices');
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int postId) async {
    await dio.post('/hr/employee-notices/$postId/read');
  }

  static EmployeeNotice _fromJson(Map<String, dynamic> json) {
    final reads = json['post_reads'] as List<dynamic>? ?? [];
    final firstRead = reads.isNotEmpty ? reads.first as Map<String, dynamic>? : null;

    return EmployeeNotice(
      id: json['id'] as int,
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      postedByName: (json['users'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Admin',
      mediaUrls: _stringList(json['media_urls']),
      mediaTypes: _stringList(json['media_types']),
      isPinned: json['is_pinned'] as bool? ?? false,
      postedAt: json['posted_at'] != null
          ? DateTime.parse(json['posted_at'] as String).toLocal()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String).toLocal()
          : null,
      isRead: reads.isNotEmpty,
      readAt: firstRead?['read_at'] != null
          ? DateTime.parse(firstRead!['read_at'] as String).toLocal()
          : null,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
