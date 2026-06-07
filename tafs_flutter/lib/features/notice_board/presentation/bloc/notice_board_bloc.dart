import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/repositories/notice_board_repository.dart';
import 'notice_board_event.dart';
import 'notice_board_state.dart';

class NoticeBoardBloc extends Bloc<NoticeBoardEvent, NoticeBoardState> {
  final NoticeBoardRepository repository;
  final Set<int> _markedReadIds = {};

  NoticeBoardBloc({required this.repository}) : super(const NoticeBoardInitial()) {
    on<NoticeBoardLoadRequested>(_onLoad);
    on<NoticeBoardNextPageRequested>(_onNextPage);
    on<NoticeBoardPostRead>(_onPostRead);
    on<NoticeBoardResetRequested>(_onReset);
  }

  Future<void> _onLoad(
    NoticeBoardLoadRequested event,
    Emitter<NoticeBoardState> emit,
  ) async {
    emit(const NoticeBoardLoading());
    try {
      final posts = await repository.getPosts();
      final unread = posts.where((p) => !p.isRead).length;
      emit(NoticeBoardLoaded(
        posts: posts,
        hasMore: posts.length == 20,
        unreadCount: unread,
      ));
    } catch (e) {
      emit(NoticeBoardError(ApiErrorMapper.fromObject(e)));
    }
  }

  Future<void> _onNextPage(
    NoticeBoardNextPageRequested event,
    Emitter<NoticeBoardState> emit,
  ) async {
    final current = state;
    if (current is! NoticeBoardLoaded) return;
    try {
      final more = await repository.getPosts(cursor: event.cursor);
      final merged = [...current.posts, ...more];
      final unread = merged.where((p) => !p.isRead).length;
      emit(current.copyWith(
        posts: merged,
        hasMore: more.length == 20,
        unreadCount: unread,
      ));
    } catch (_) {}
  }

  Future<void> _onPostRead(
    NoticeBoardPostRead event,
    Emitter<NoticeBoardState> emit,
  ) async {
    if (_markedReadIds.contains(event.postId)) return;
    _markedReadIds.add(event.postId);

    final current = state;
    if (current is NoticeBoardLoaded) {
      final updated = current.posts.map((p) {
        return p.id == event.postId ? p.copyWith(isRead: true) : p;
      }).toList();
      final unread = updated.where((p) => !p.isRead).length;
      emit(current.copyWith(posts: updated, unreadCount: unread));
    }

    repository.markRead(event.postId).catchError((_) {});
  }

  void _onReset(
    NoticeBoardResetRequested event,
    Emitter<NoticeBoardState> emit,
  ) {
    _markedReadIds.clear();
    emit(const NoticeBoardInitial());
  }
}
