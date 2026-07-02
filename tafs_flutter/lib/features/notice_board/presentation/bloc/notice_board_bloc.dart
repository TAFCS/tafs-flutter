import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/entities/attendance_alert.dart';
import '../../domain/entities/calendar_alert.dart';
import '../../domain/entities/notice_feed_item.dart';
import '../../domain/entities/notice_post.dart';
import '../../domain/entities/voucher_alert.dart';
import '../../domain/repositories/notice_board_repository.dart';
import 'notice_board_event.dart';
import 'notice_board_state.dart';

class NoticeBoardBloc extends Bloc<NoticeBoardEvent, NoticeBoardState> {
  final NoticeBoardRepository repository;
  final Set<String> _markedReadIds = {};
  final List<VoucherAlert> _pendingVoucherAlerts = [];
  bool _refreshRequestedWhileLoading = false;
  int _loadGeneration = 0;

  NoticeBoardBloc({required this.repository}) : super(const NoticeBoardInitial()) {
    on<NoticeBoardLoadRequested>(_onLoad);
    on<NoticeBoardRefreshRequested>(_onRefresh);
    on<NoticeBoardVoucherAlertReceived>(_onVoucherAlertReceived);
    on<NoticeBoardNextPageRequested>(_onNextPage);
    on<NoticeBoardPostRead>(_onPostRead);
    on<NoticeBoardAlertRead>(_onAlertRead);
    on<NoticeBoardCalendarAlertRead>(_onCalendarAlertRead);
    on<NoticeBoardVoucherAlertRead>(_onVoucherAlertRead);
    on<NoticeBoardResetRequested>(_onReset);
  }

  List<NoticeFeedItem> _mergeAndSort(
    List<NoticePost> posts,
    List<AttendanceAlert> alerts,
    List<CalendarAlert> calendarAlerts,
    List<VoucherAlert> voucherAlerts,
  ) {
    final items = <NoticeFeedItem>[
      ...posts.map((p) => NoticeFeedPost(p)),
      ...alerts.map((a) => NoticeFeedAlert(a)),
      ...calendarAlerts.map((c) => NoticeFeedCalendarAlert(c)),
      ...voucherAlerts.map((v) => NoticeFeedVoucherAlert(v)),
    ];
    items.sort((a, b) {
      final aPinned = (a is NoticeFeedPost && a.post.isPinned) ||
          (a is NoticeFeedCalendarAlert && a.alert.isPinned);
      final bPinned = (b is NoticeFeedPost && b.post.isPinned) ||
          (b is NoticeFeedCalendarAlert && b.alert.isPinned);
      if (aPinned != bPinned) return aPinned ? -1 : 1;

      return b.timestamp.compareTo(a.timestamp);
    });
    return items;
  }

  Future<({
    List<NoticePost> posts,
    List<AttendanceAlert> alerts,
    List<CalendarAlert> calendarAlerts,
    List<VoucherAlert> voucherAlerts,
  })> _fetchFeed() async {
    final results = await Future.wait([
      repository.getPosts(),
      repository.getAttendanceAlerts(),
      repository.getCalendarAlerts(),
      repository.getVoucherAlerts(),
    ]);
    return (
      posts: results[0] as List<NoticePost>,
      alerts: results[1] as List<AttendanceAlert>,
      calendarAlerts: results[2] as List<CalendarAlert>,
      voucherAlerts: results[3] as List<VoucherAlert>,
    );
  }

  Future<void> _onLoad(
    NoticeBoardLoadRequested event,
    Emitter<NoticeBoardState> emit,
  ) async {
    final generation = ++_loadGeneration;
    emit(const NoticeBoardLoading());
    try {
      final feed = await _fetchFeed();
      if (generation != _loadGeneration) return;

      final items = _mergeAndSort(
        feed.posts,
        feed.alerts,
        feed.calendarAlerts,
        _mergePendingVoucherAlerts(feed.voucherAlerts),
      );
      final unread = items.where((i) => !i.isRead).length;
      emit(NoticeBoardLoaded(
        items: items,
        hasMore: feed.posts.length == 20,
        unreadCount: unread,
      ));

      if (_refreshRequestedWhileLoading) {
        _refreshRequestedWhileLoading = false;
        add(const NoticeBoardRefreshRequested());
      }
    } catch (e) {
      if (generation != _loadGeneration) return;
      emit(NoticeBoardError(ApiErrorMapper.fromObject(e)));
    }
  }

  Future<void> _onRefresh(
    NoticeBoardRefreshRequested event,
    Emitter<NoticeBoardState> emit,
  ) async {
    final previous = state;
    if (previous is NoticeBoardLoading) {
      _refreshRequestedWhileLoading = true;
      return;
    }
    if (previous is NoticeBoardInitial) {
      add(const NoticeBoardLoadRequested());
      return;
    }
    if (previous is! NoticeBoardLoaded) {
      add(const NoticeBoardLoadRequested());
      return;
    }

    try {
      final feed = await _fetchFeed();
      final items = _mergeAndSort(
        feed.posts,
        feed.alerts,
        feed.calendarAlerts,
        _mergePendingVoucherAlerts(feed.voucherAlerts),
      );
      final unread = items.where((i) => !i.isRead).length;
      emit(previous.copyWith(
        items: items,
        hasMore: feed.posts.length == 20,
        unreadCount: unread,
      ));
    } catch (_) {}
  }

  List<VoucherAlert> _mergePendingVoucherAlerts(List<VoucherAlert> fromApi) {
    if (_pendingVoucherAlerts.isEmpty) return fromApi;

    final merged = [...fromApi];
    for (final pending in _pendingVoucherAlerts) {
      if (!merged.any((alert) => alert.id == pending.id)) {
        merged.add(pending);
      }
    }
    return merged;
  }

  void _queuePendingVoucherAlert(VoucherAlert alert) {
    if (_pendingVoucherAlerts.any((pending) => pending.id == alert.id)) return;
    _pendingVoucherAlerts.add(alert);
  }

  void _onVoucherAlertReceived(
    NoticeBoardVoucherAlertReceived event,
    Emitter<NoticeBoardState> emit,
  ) {
    final current = state;
    if (current is! NoticeBoardLoaded) {
      _queuePendingVoucherAlert(event.alert);
      return;
    }

    final alreadyPresent = current.items
        .whereType<NoticeFeedVoucherAlert>()
        .any((item) => item.alert.id == event.alert.id);
    if (alreadyPresent) return;

    final existingPosts = current.items.whereType<NoticeFeedPost>().map((i) => i.post).toList();
    final existingAlerts = current.items.whereType<NoticeFeedAlert>().map((i) => i.alert).toList();
    final existingCalendarAlerts =
        current.items.whereType<NoticeFeedCalendarAlert>().map((i) => i.alert).toList();
    final existingVoucherAlerts =
        current.items.whereType<NoticeFeedVoucherAlert>().map((i) => i.alert).toList();

    final items = _mergeAndSort(
      existingPosts,
      existingAlerts,
      existingCalendarAlerts,
      [...existingVoucherAlerts, event.alert],
    );
    final unread = items.where((i) => !i.isRead).length;
    emit(current.copyWith(items: items, unreadCount: unread));
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
      final existingVoucherAlerts = current.items.whereType<NoticeFeedVoucherAlert>().map((i) => i.alert).toList();
      final items = _mergeAndSort(
        [...existingPosts, ...more],
        existingAlerts,
        existingCalendarAlerts,
        existingVoucherAlerts,
      );
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

  Future<void> _onVoucherAlertRead(
    NoticeBoardVoucherAlertRead event,
    Emitter<NoticeBoardState> emit,
  ) async {
    final key = 'voucher-alert-${event.alertId}';
    if (_markedReadIds.contains(key)) return;
    _markedReadIds.add(key);

    final current = state;
    if (current is NoticeBoardLoaded) {
      final updated = current.items.map((item) {
        if (item is NoticeFeedVoucherAlert && item.alert.id == event.alertId) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      final unread = updated.where((i) => !i.isRead).length;
      emit(current.copyWith(items: updated, unreadCount: unread));
    }

    repository.markVoucherAlertRead(event.alertId).catchError((_) {});
  }

  void _onReset(
    NoticeBoardResetRequested event,
    Emitter<NoticeBoardState> emit,
  ) {
    _markedReadIds.clear();
    _pendingVoucherAlerts.clear();
    _refreshRequestedWhileLoading = false;
    _loadGeneration++;
    emit(const NoticeBoardInitial());
  }
}
