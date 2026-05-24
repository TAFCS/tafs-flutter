import 'package:dio/dio.dart';
import '../models/notice_post_dto.dart';

class NoticeBoardRemoteDataSource {
  final Dio dio;

  NoticeBoardRemoteDataSource(this.dio);

  Future<List<NoticePostDto>> getPosts({int? cursor}) async {
    final response = await dio.get(
      '/notice-board',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => NoticePostDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(int postId) async {
    await dio.post('/notice-board/$postId/read');
  }
}
