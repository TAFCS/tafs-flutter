import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// A shimmering placeholder list shown while the Notice Board feed is loading.
class NoticeBoardSkeletonList extends StatelessWidget {
  final int count;

  const NoticeBoardSkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          count,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space3),
            child: _NoticeCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _NoticeCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowXs,
      ),
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonBox(width: 34, height: 34, shape: BoxShape.circle),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(width: 110, height: 11),
                    SizedBox(height: 6),
                    _SkeletonBox(width: 60, height: 9),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          const _SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          const _SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          const _SkeletonBox(width: 160, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BoxShape shape;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.blue100.withValues(alpha: 0.5),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(4) : null,
      ),
    );
  }
}

/// Sweeps a moving highlight gradient across [child]. Self-contained (no
/// external package) since the app has no shimmer dependency elsewhere.
class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              colors: [
                AppTheme.blue100.withValues(alpha: 0.0),
                AppTheme.white.withValues(alpha: 0.85),
                AppTheme.blue100.withValues(alpha: 0.0),
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-3.0 + 6.0 * t, 0),
              end: Alignment(-1.0 + 6.0 * t, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
