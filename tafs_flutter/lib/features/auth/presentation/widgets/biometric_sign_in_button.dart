import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BiometricSignInButton extends StatelessWidget {
  const BiometricSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space3,
              vertical: AppTheme.space1,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                  )
                : _BiometricIcon(),
          ),
        ),
        const SizedBox(height: AppTheme.space1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Sign in with $label',
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _BiometricIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final asset = Platform.isIOS ? 'assets/face_id.png' : 'assets/fingerprint.png';

    return Image.asset(
      asset,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
    );
  }
}
