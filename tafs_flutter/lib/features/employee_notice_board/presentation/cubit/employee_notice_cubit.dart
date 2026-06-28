import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/employee_notice.dart';
import '../../domain/repositories/employee_notice_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class EmployeeNoticeState {
  final List<EmployeeNotice> notices;
  final bool loading;
  final String? error;

  const EmployeeNoticeState({
    this.notices = const [],
    this.loading = false,
    this.error,
  });

  bool get hasUnread => notices.any((n) => !n.isRead);

  EmployeeNoticeState copyWith({
    List<EmployeeNotice>? notices,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      EmployeeNoticeState(
        notices: notices ?? this.notices,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class EmployeeNoticeCubit extends Cubit<EmployeeNoticeState> {
  final EmployeeNoticeRepository repository;
  bool _initialized = false;

  EmployeeNoticeCubit({required this.repository})
      : super(const EmployeeNoticeState());

  Future<void> load() async {
    if (_initialized) {
      await refresh();
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final notices = _sorted(await repository.getFeed());
      _initialized = true;
      emit(EmployeeNoticeState(notices: notices, loading: false));
    } catch (_) {
      emit(state.copyWith(loading: false, error: 'Failed to load notices.'));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final notices = _sorted(await repository.getFeed());
      emit(state.copyWith(notices: notices, loading: false));
    } catch (_) {
      emit(state.copyWith(loading: false, error: 'Failed to refresh notices.'));
    }
  }

  Future<void> markRead(int postId) async {
    try {
      await repository.markRead(postId);
      final updated = state.notices.map((n) {
        if (n.id == postId && !n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();
      emit(state.copyWith(notices: updated));
    } catch (_) {
      // Fire-and-forget — silently ignore errors
    }
  }

  void reset() {
    _initialized = false;
    emit(const EmployeeNoticeState());
  }

  static List<EmployeeNotice> _sorted(List<EmployeeNotice> notices) {
    final sorted = List<EmployeeNotice>.from(notices);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.postedAt.compareTo(a.postedAt);
    });
    return sorted;
  }
}
