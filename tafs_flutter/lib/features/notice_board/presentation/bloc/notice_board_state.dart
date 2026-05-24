import 'package:equatable/equatable.dart';
import '../../domain/entities/notice_post.dart';

abstract class NoticeBoardState extends Equatable {
  const NoticeBoardState();

  @override
  List<Object?> get props => [];
}

class NoticeBoardInitial extends NoticeBoardState {
  const NoticeBoardInitial();
}

class NoticeBoardLoading extends NoticeBoardState {
  const NoticeBoardLoading();
}

class NoticeBoardLoaded extends NoticeBoardState {
  final List<NoticePost> posts;
  final bool hasMore;
  final int unreadCount;

  const NoticeBoardLoaded({
    required this.posts,
    required this.hasMore,
    required this.unreadCount,
  });

  NoticeBoardLoaded copyWith({
    List<NoticePost>? posts,
    bool? hasMore,
    int? unreadCount,
  }) {
    return NoticeBoardLoaded(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [posts, hasMore, unreadCount];
}

class NoticeBoardError extends NoticeBoardState {
  final String message;
  const NoticeBoardError(this.message);

  @override
  List<Object?> get props => [message];
}
