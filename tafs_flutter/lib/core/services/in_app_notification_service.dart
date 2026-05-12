import 'package:flutter/material.dart';
import '../widgets/notification_banner.dart';

class InAppNotificationService {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? iconUrl,
    required VoidCallback onTap,
  }) {
    // Remove existing if any
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    
    _currentEntry = OverlayEntry(
      builder: (context) => _NotificationWrapper(
        title: title,
        message: message,
        iconUrl: iconUrl,
        onTap: () {
          _currentEntry?.remove();
          _currentEntry = null;
          onTap();
        },
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);
    
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_currentEntry != null) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }
}

class _NotificationWrapper extends StatefulWidget {
  final String title;
  final String message;
  final String? iconUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationWrapper({
    required this.title,
    required this.message,
    this.iconUrl,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<_NotificationWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: NotificationBanner(
            title: widget.title,
            message: widget.message,
            iconUrl: widget.iconUrl,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
