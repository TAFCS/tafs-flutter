import '../../domain/entities/notice_post.dart';
import '../../domain/repositories/notice_board_repository.dart';
import '../datasources/notice_board_remote_data_source.dart';

class NoticeBoardRepositoryImpl implements NoticeBoardRepository {
  final NoticeBoardRemoteDataSource remoteDataSource;

  NoticeBoardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NoticePost>> getPosts({int? cursor}) {
    return remoteDataSource.getPosts(cursor: cursor);
  }

  @override
  Future<void> markRead(int postId) {
    return remoteDataSource.markRead(postId);
  }
}
