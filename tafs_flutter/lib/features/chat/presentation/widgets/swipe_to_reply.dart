import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _SwipeToReplyState extends State<SwipeToReply> {
  double _dragValue = 0.0;
  static const double _threshold = 48.0;
  static const double _maxDrag = 72.0;
  bool _hasTriggeredReply = false;
  bool _axisResolved = false;
  bool _isHorizontal = false;
  double _totalDx = 0;
  double _totalDy = 0;

  void _resetDrag() {
    setState(() {
      _dragValue = 0.0;
      _hasTriggeredReply = false;
      _axisResolved = false;
      _isHorizontal = false;
      _totalDx = 0;
      _totalDy = 0;
    });
  }

  void _onPanStart(DragStartDetails details) {
    _axisResolved = false;
    _isHorizontal = false;
    _totalDx = 0;
    _totalDy = 0;
    _hasTriggeredReply = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_axisResolved) {
      _totalDx += details.delta.dx;
      _totalDy += details.delta.dy.abs();
      if (_totalDx.abs() < 8 && _totalDy < 8) return;
      _axisResolved = true;
      _isHorizontal = _totalDx > _totalDy;
      if (!_isHorizontal) return;
    }

    if (!_isHorizontal) return;

    setState(() {
      _dragValue += details.delta.dx;
      if (_dragValue < 0.0) _dragValue = 0.0;
      if (_dragValue > _maxDrag) _dragValue = _maxDrag;

      if (_dragValue >= _threshold && !_hasTriggeredReply) {
        HapticFeedback.lightImpact();
        _hasTriggeredReply = true;
        widget.onReply();
      } else if (_dragValue < _threshold) {
        _hasTriggeredReply = false;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isHorizontal) {
      _resetDrag();
    } else {
      _axisResolved = false;
      _isHorizontal = false;
      _totalDx = 0;
      _totalDy = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _resetDrag,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Opacity(
              opacity: (_dragValue / _threshold).clamp(0.0, 1.0),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.reply, color: Colors.grey, size: 16),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragValue, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
