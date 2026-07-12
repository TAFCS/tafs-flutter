import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A screen-locking loading overlay: blocks all touch input behind it and
/// shows a centered spinner + optional message. Used for auth transitions
/// (login/logout) where a stray tap could double-submit the request.
class FullScreenLoader extends StatelessWidget {
  final String? message;

  const FullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: AppTheme.navy.withValues(alpha: 0.55),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.white,
                ),
                if (message != null) ...[
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    message!,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
