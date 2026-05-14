import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final LinearGradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? (isPrimary ? AppTheme.navyGradient : null);

    return Container(
      width: double.infinity,
      height: 52,
      decoration: effectiveGradient != null && onPressed != null && !isLoading
          ? BoxDecoration(
              gradient: effectiveGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: AppTheme.shadowSm,
            )
          : null,
      child: isPrimary
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: effectiveGradient != null
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                    )
                  : null,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                      ),
                    )
                  : Text(text.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                side: const BorderSide(color: AppTheme.navy, width: 1.5),
                foregroundColor: AppTheme.navy,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.navy),
                      ),
                    )
                  : Text(text.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
    );
  }
}
