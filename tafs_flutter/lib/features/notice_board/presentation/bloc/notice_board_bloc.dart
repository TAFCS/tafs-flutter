import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/entities/attendance_alert.dart';
import '../../domain/entities/calendar_alert.dart';
import '../../domain/entities/notice_feed_item.dart';
import '../../domain/entities/notice_post.dart';
import '../../domain/repositories/notice_board_repository.dart';
import 'notice_board_event.dart';
import 'notice_board_state.dart';

class NoticeBoardBloc extends Bloc<NoticeBoardEvent, NoticeBoardState> {
  final NoticeBoardRepository repository;
  final Set<String> _markedReadIds = {};

  NoticeBoardBloc({required this.repository}) : super(const NoticeBoardInitial()) {
    on<NoticeBoardLoadRequested>(_onLoad);
    on<NoticeBoardNextPageRequested>(_onNextPage);
    on<NoticeBoardPostRead>(_onPostRead);
    on<NoticeBoardAlertRead>(_onAlertRead);
    on<NoticeBoardCalendarAlertRead>(_onCalendarAlertRead);
    on<NoticeBoardResetRequested>(_onReset);
  }

  // Merges posts, attendance alerts, and calendar alerts into one feed, sorted by recency.
  // Pinned posts are always pulled to the top, matching the existing
  // notice-board ordering.
  List<NoticeFeedItem> _mergeAndSort(
    List<NoticePost> posts,
    List<AttendanceAlert> alerts,
    List<CalendarAlert> calendarAlerts,
  ) {
    final items = <NoticeFeedItem>[
      ...posts.map((p) => NoticeFeedPost(p)),
      ...alerts.map((a) => NoticeFeedAlert(a)),
      ...calendarAlerts.map((c) => NoticeFeedCalendarAlert(c)),
    ];
    items.sort((a, b) {
      final aPinned = a is NoticeFeedPost && a.post.isPinned;
      final bPinned = b is NoticeFeedPost && b.post.isPinned;
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      return b.timestamp.compareTo(a.timestamp);
    });
    return items;
  }

  Future<void> _onLoad(
    NoticeBoardLoadRequested event,
    Emitter<NoticeBoardState> emit,
  ) async {
    emit(const NoticeBoardLoading());
    try {
      final results = await Future.wait([
        repository.getPosts(),
        repository.getAttendanceAlerts(),
        repository.getCalendarAlerts(),
      ]);
      final posts = results[0] as List<NoticePost>;
      final alerts = results[1] as List<AttendanceAlert>;
      final calendarAlerts = results[2] as List<CalendarAlert>;
      final items = _mergeAndSort(posts, alerts, calendarAlerts);
      final unread = items.where((i) => !i.isRead).length;
      emit(NoticeBoardLoaded(
        items: items,
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
      final existingPosts = current.items.whereType<NoticeFeedPost>().map((i) => i.post).toList();
      final existingAlerts = current.items.whereType<NoticeFeedAlert>().map((i) => i.alert).toList();
      final existingCalendarAlerts = current.items.whereType<NoticeFeedCalendarAlert>().map((i) => i.alert).toList();
      final items = _mergeAndSort([...existingPosts, ...more], existingAlerts, existingCalendarAlerts);
      final unread = items.where((i) => !i.isRead).length;
      emit(current.copyWith(
        items: items,
        hasMore: more.length == 20,
        unreadCount: unread,
      ));
    } catch (_) {}
  }

  Future<void> _onPostRead(
    NoticeBoardPostRead event,
    Emitter<NoticeBoardState> emit,
  ) async {
    final key = 'post-${event.postId}';
    if (_markedReadIds.contains(key)) return;
    _markedReadIds.add(key);

    final current = state;
    if (current is NoticeBoardLoaded) {
      final updated = current.items.map((item) {
        if (item is NoticeFeedPost && item.post.id == event.postId) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      final unread = updated.where((i) => !i.isRead).length;
      emit(current.copyWith(items: updated, unreadCount: unread));
    }

    repository.markRead(event.postId).catchError((_) {});
  }

  Future<void> _onAlertRead(
    NoticeBoardAlertRead event,
    Emitter<NoticeBoardState> emit,
  ) async {
    final key = 'alert-${event.alertId}';
    if (_markedReadIds.contains(key)) return;
    _markedReadIds.add(key);

    final current = state;
    if (current is NoticeBoardLoaded) {
      final updated = current.items.map((item) {
        if (item is NoticeFeedAlert && item.alert.id == event.alertId) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      final unread = updated.where((i) => !i.isRead).length;
      emit(current.copyWith(items: updated, unreadCount: unread));
    }

    repository.markAlertRead(event.alertId).catchError((_) {});
  }

  Future<void> _onCalendarAlertRead(
    NoticeBoardCalendarAlertRead event,
    Emitter<NoticeBoardState> emit,
  ) async {
    final key = 'cal-alert-${event.alertId}';
    if (_markedReadIds.contains(key)) return;
    _markedReadIds.add(key);

    final current = state;
    if (current is NoticeBoardLoaded) {
      final updated = current.items.map((item) {
        if (item is NoticeFeedCalendarAlert && item.alert.id == event.alertId) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      final unread = updated.where((i) => !i.isRead).length;
      emit(current.copyWith(items: updated, unreadCount: unread));
    }

    repository.markCalendarAlertRead(event.alertId).catchError((_) {});
  }

  void _onReset(
    NoticeBoardResetRequested event,
    Emitter<NoticeBoardState> emit,
  ) {
    _markedReadIds.clear();
    emit(const NoticeBoardInitial());
  }
}
