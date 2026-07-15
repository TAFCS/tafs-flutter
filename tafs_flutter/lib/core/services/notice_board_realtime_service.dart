import 'dart:async';

import '../../features/notice_board/presentation/bloc/notice_board_event.dart';
import '../../injection_container.dart';
import '../navigation/app_navigator.dart';
import 'in_app_notification_service.dart';

/// Listens for parent notice-board posts over the chat socket (mirrors
/// [VoucherAlertRealtimeService]) so the home feed updates and the in-app
/// banner shows while the app is open — even when FCM is delayed or unavailable
/// (e.g. iOS Simulator).
class NoticeBoardRealtimeService {
  NoticeBoardRealtimeService._();

  static final NoticeBoardRealtimeService instance =
      NoticeBoardRealtimeService._();

  StreamSubscription<Map<String, dynamic>>? _noticeSub;
  bool _started = false;
  final Set<int> _shownPostIds = {};

  void start() {
    if (_started) return;
    _started = true;

    _noticeSub =
        InjectionContainer.chatRepository.onNoticeBoardPayload.listen(_onPayload);
  }

  void stop() {
    _noticeSub?.cancel();
    _noticeSub = null;
    _started = false;
    _shownPostIds.clear();
  }

  void _onPayload(Map<String, dynamic> data) {
    handleIncoming(
      title: data['title'] as String?,
      body: data['body'] as String?,
      postId: data['post_id'],
    );
  }

  /// Shared entry for socket + foreground FCM so we refresh once and dedupe banners.
  void handleIncoming({
    String? title,
    String? body,
    Object? postId,
  }) {
    InjectionContainer.noticeBoardBloc
        .add(const NoticeBoardRefreshRequested());
    _showBanner(title: title, body: body, postId: postId);
  }

  void _showBanner({
    String? title,
    String? body,
    Object? postId,
  }) {
    final parsedPostId = _parseInt(postId);
    if (parsedPostId != null && !_shownPostIds.add(parsedPostId)) return;

    final trimmedTitle = title?.trim();
    final trimmedBody = body?.trim() ?? '';
    final displayTitle = (trimmedTitle != null && trimmedTitle.isNotEmpty)
        ? trimmedTitle
        : 'New School Notice';
    final preview = trimmedBody.length > 80
        ? '${trimmedBody.substring(0, 80)}…'
        : trimmedBody;

    InAppNotificationService.show(
      title: displayTitle,
      message:
          preview.isNotEmpty ? preview : 'Tap to view the latest notice.',
      onTap: switchToHomeTab,
    );
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
