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
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            color: AppTheme.navy.withValues(alpha: 0.75),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space5,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowLg,
                    border: Border.all(color: AppTheme.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppTheme.white,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
