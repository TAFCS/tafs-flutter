import 'package:flutter/material.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragValue = 0.0;
  static const double _threshold = 50.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.2, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx > 0) {
      setState(() {
        _dragValue += details.delta.dx;
        if (_dragValue > _threshold * 1.5) _dragValue = _threshold * 1.5;
        _controller.value = _dragValue / (_threshold * 3);
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragValue >= _threshold) {
      widget.onReply();
      // Provide haptic feedback if possible, but let's keep it simple
    }
    setState(() {
      _dragValue = 0.0;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Opacity(
              opacity: (_dragValue / _threshold).clamp(0.0, 1.0),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.reply, color: Colors.grey[700], size: 16),
              ),
            ),
          ),
          SlideTransition(
            position: _animation,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
