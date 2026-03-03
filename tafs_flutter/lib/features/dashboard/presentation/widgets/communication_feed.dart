import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CommunicationFeed extends StatelessWidget {
  const CommunicationFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Communication Feed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 16),
        // Priority Alert / Push Notification
        _buildAlertCard(
          title: 'Fee Reminder: Dec Cycle',
          message: 'Your challan for the December term is due on the 10th. Please pay to avoid late fees.',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.accent,
        ),
        const SizedBox(height: 12),
        // Institutional Data Alert
        _buildAlertCard(
          title: 'School Reopening',
          message: 'Main Campus will resume regular classes on Monday at 08:00 AM.',
          icon: Icons.info_outline,
          color: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: const BorderSide(color: AppTheme.borderSubtle),
          right: const BorderSide(color: AppTheme.borderSubtle),
          bottom: const BorderSide(color: AppTheme.borderSubtle),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
