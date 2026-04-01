import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../fee_ledger/presentation/pages/fee_ledger_page.dart';

class LiveLedgerCard extends StatelessWidget {
  final int studentCc;
  final String studentName;

  const LiveLedgerCard({
    super.key,
    required this.studentCc,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeeLedgerPage(
            studentCc: studentCc,
            studentName: studentName,
          ),
        ),
      ),
      child: Card(
        elevation: 2,
        shadowColor: AppTheme.shadowL2[0].color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        color: AppTheme.surface2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Ledger',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Total Outstanding',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Rs. 45,000',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 24),
              // Installment Tracker
              const Text(
                'Admission Fee Installments (3/8 Cleared)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 3 / 8,
                backgroundColor: AppTheme.background,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.sync, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Last synced with Bank/PayPro: 10 mins ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
