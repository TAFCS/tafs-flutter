import 'package:flutter/material.dart';
import '../widgets/notification_banner.dart';

class _BannerRequest {
  final String title;
  final String message;
  final String? iconUrl;
  final VoidCallback onTap;
  final int id;

  const _BannerRequest({
    required this.title,
    required this.message,
    required this.onTap,
    required this.id,
    this.iconUrl,
  });
}

/// In-app top banner. Prefer this over raw [Overlay.insert] — MaterialApp's
/// `builder` wrapping can make overlay entries hard to see / racey.
class InAppNotificationService {
  InAppNotificationService._();

  static final ValueNotifier<_BannerRequest?> _request =
      ValueNotifier<_BannerRequest?>(null);
  static int _seq = 0;

  /// Returns `true` when a banner was queued for display.
  ///
  /// [context] is unused (kept for call-site compatibility). Painting is done
  /// by [InAppNotificationHost] under [MaterialApp.builder].
  static bool show({
    BuildContext? context,
    required String title,
    required String message,
    String? iconUrl,
    required VoidCallback onTap,
  }) {
    _request.value = _BannerRequest(
      id: ++_seq,
      title: title,
      message: message,
      iconUrl: iconUrl,
      onTap: onTap,
    );
    return true;
  }

  static void dismiss() {
    _request.value = null;
  }
}

/// Place above the navigator in [MaterialApp.builder] so banners always show.
class InAppNotificationHost extends StatelessWidget {
  const InAppNotificationHost({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_BannerRequest?>(
      valueListenable: InAppNotificationService._request,
      builder: (context, request, _) {
        // Positioned must stay a direct layout child of the outer Stack via
        // this host always occupying the top slot.
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 0,
          right: 0,
          child: request == null
              ? const SizedBox.shrink()
              : _NotificationWrapper(
                  key: ValueKey(request.id),
                  title: request.title,
                  message: request.message,
                  iconUrl: request.iconUrl,
                  onTap: () {
                    InAppNotificationService.dismiss();
                    request.onTap();
                  },
                  onDismiss: InAppNotificationService.dismiss,
                ),
        );
      },
    );
  }
}

class _NotificationWrapper extends StatefulWidget {
  final String title;
  final String message;
  final String? iconUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationWrapper({
    super.key,
    required this.title,
    required this.message,
    this.iconUrl,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<_NotificationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Dismissible(
          key: ValueKey('banner_${widget.key}'),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss(),
          child: NotificationBanner(
            title: widget.title,
            message: widget.message,
            iconUrl: widget.iconUrl,
            onTap: () async {
              await _dismiss();
              widget.onTap();
            },
          ),
        ),
      ),
    );
  }
}
