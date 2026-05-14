import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import '../../../fee_ledger/presentation/bloc/fee_summary_state.dart';
import '../../../fee_ledger/presentation/pages/fee_ledger_page.dart';

class LiveLedgerCard extends StatelessWidget {
  final int studentCc;
  final String studentName;
  final VoidCallback? onTap;

  const LiveLedgerCard({
    super.key,
    required this.studentCc,
    required this.studentName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return BlocBuilder<FeeSummaryBloc, FeeSummaryState>(
      builder: (context, state) {
        if (state is FeeSummaryLoading) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.blue100),
            ),
            child: const Center(child: CircularProgressIndicator(color: AppTheme.navy)),
          );
        }

        if (state is FeeSummaryError) {
          return Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 32),
                const SizedBox(height: AppTheme.space3),
                Text(
                  'Failed to load ledger data',
                  style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
                ),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.blue300, fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (state is! FeeSummaryLoaded) return const SizedBox.shrink();

        final summary = state.summary;
        final bool isClear = !summary.hasOverdue;

        return GestureDetector(
          onTap: onTap ?? () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeeLedgerPage(
                studentCc: studentCc,
                studentName: studentName,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: isClear ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.blue100),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isClear ? Icons.verified_user_rounded : Icons.account_balance_wallet_rounded,
                            color: isClear ? AppTheme.success : AppTheme.navy,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Ledger',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isClear ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          isClear ? 'ALL CLEAR' : 'UNPAID',
                          style: TextStyle(
                            color: isClear ? AppTheme.success : AppTheme.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space5),
                  Text(
                    cur.format(summary.outstandingBalance),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isClear ? AppTheme.success : AppTheme.navy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.space3),
                    decoration: BoxDecoration(
                      color: isClear ? AppTheme.success.withValues(alpha: 0.05) : AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isClear ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                          size: 14,
                          color: isClear ? AppTheme.success : AppTheme.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isClear ? 'Fees are fully settled.' : '${summary.overdueCount} pending vouchers found.',
                          style: TextStyle(
                            color: isClear ? AppTheme.success : AppTheme.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Annual Fee Progress (${summary.academicYear})',
                        style: const TextStyle(fontSize: 12, color: AppTheme.blue300, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${((summary.totalPaid / (summary.totalCharged > 0 ? summary.totalCharged : 1)) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navy),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    child: LinearProgressIndicator(
                      value: summary.totalCharged > 0 ? (summary.totalPaid / summary.totalCharged) : 0,
                      backgroundColor: AppTheme.blue100.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(isClear ? AppTheme.success : AppTheme.navy),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space6),
                  const Divider(color: AppTheme.blue100),
                  const SizedBox(height: AppTheme.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'View Full History',
                        style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.navy),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
