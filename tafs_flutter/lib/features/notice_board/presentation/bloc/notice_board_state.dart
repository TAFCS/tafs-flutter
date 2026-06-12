import 'package:equatable/equatable.dart';
import '../../domain/entities/notice_feed_item.dart';

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
  final List<NoticeFeedItem> items;
  final bool hasMore;
  final int unreadCount;

  const NoticeBoardLoaded({
    required this.items,
    required this.hasMore,
    required this.unreadCount,
  });

  NoticeBoardLoaded copyWith({
    List<NoticeFeedItem>? items,
    bool? hasMore,
    int? unreadCount,
  }) {
    return NoticeBoardLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [items, hasMore, unreadCount];
}

class NoticeBoardError extends NoticeBoardState {
  final String message;
  const NoticeBoardError(this.message);

  @override
  List<Object?> get props => [message];
}
