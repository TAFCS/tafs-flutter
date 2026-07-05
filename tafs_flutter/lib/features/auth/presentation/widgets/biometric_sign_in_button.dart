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
              horizontal: AppTheme.space4,
              vertical: AppTheme.space2,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 72,
                    height: 72,
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
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
        const SizedBox(height: AppTheme.space2),
        Text(
          'Sign in with $label',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
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
        width:36,
        height: 36,
      fit: BoxFit.contain,
    );
  }
}
