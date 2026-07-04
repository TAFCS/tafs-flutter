import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/staff_notice_post_dto.dart';

class StaffNoticeBoardRemoteDataSource {
  final Dio dio;

  StaffNoticeBoardRemoteDataSource(this.dio);

  Future<List<StaffNoticePostDto>> getPosts({int? cursor}) async {
    final response = await dio.get(
      '/admin/notice-board',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => StaffNoticePostDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoticeReadStatsDto> getReadStats(int postId) async {
    final response = await dio.get('/admin/notice-board/$postId/reads');
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? data
        : (data['data'] as Map<String, dynamic>);
    return NoticeReadStatsDto.fromJson(map);
  }

  Future<StaffNoticePostDto> createPost(Map<String, dynamic> body) async {
    final response = await dio.post('/admin/notice-board', data: body);
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? data
        : (data['data'] as Map<String, dynamic>);
    return StaffNoticePostDto.fromJson(map);
  }

  Future<StaffNoticePostDto> updatePost(
    int postId,
    Map<String, dynamic> body,
  ) async {
    final response = await dio.patch('/admin/notice-board/$postId', data: body);
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? data
        : (data['data'] as Map<String, dynamic>);
    if (map.containsKey('users') && map.containsKey('_count')) {
      return StaffNoticePostDto.fromJson(map);
    }
    return StaffNoticePostDto(
      id: map['id'] as int? ?? postId,
      title: map['title'] as String?,
      body: map['body'] as String? ?? '',
      postedByName: 'Admin',
      campusIds: const [],
      classIds: const [],
      sectionIds: const [],
      mediaUrls: const [],
      mediaTypes: const [],
      isPinned: map['is_pinned'] as bool? ?? false,
      postedAt: map['posted_at'] != null
          ? DateTime.parse(map['posted_at'] as String)
          : DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      readCount: 0,
    );
  }

  Future<void> deletePost(int postId) async {
    await dio.delete('/admin/notice-board/$postId');
  }

  Future<Map<String, String>> uploadMedia(XFile file) async {
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
    final res = await dio.post('/admin/notice-board/upload', data: form);
    final data = res.data;
    final map = data is Map<String, dynamic>
        ? data
        : (data['data'] as Map<String, dynamic>);
    return {
      'url': map['url'] as String,
      'type': map['type'] as String? ?? 'misc',
    };
  }

  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    final response = await dio.get('/students/search-simple', queryParameters: {'q': query});
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<CampusScopeDto>> getCampuses() async {
    final response = await dio.get('/campuses');
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => CampusScopeDto.fromJson(e as Map<String, dynamic>))
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
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
