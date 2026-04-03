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

  const LiveLedgerCard({
    super.key,
    required this.studentCc,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return BlocBuilder<FeeSummaryBloc, FeeSummaryState>(
      builder: (context, state) {
        if (state is FeeSummaryLoading) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is FeeSummaryError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Failed to load fee ledger\n${state.message}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          );
        }

        if (state is! FeeSummaryLoaded) return const SizedBox.shrink();

        final summary = state.summary;
        final bool isClear = !summary.hasOverdue;

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
              side: BorderSide(
                color: isClear
                    ? Colors.green.withValues(alpha: 0.3)
                    : AppTheme.borderSubtle,
              ),
            ),
            color: isClear
                ? Colors.green.withValues(alpha: 0.02)
                : AppTheme.surface2,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isClear
                              ? Colors.green.withValues(alpha: 0.1)
                              : AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isClear ? 'All Clear' : 'Overdue',
                          style: TextStyle(
                            color: isClear ? Colors.green : AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cur.format(summary.outstandingBalance),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isClear ? Colors.green : AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Installment/Fee Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Academic Year Fees (${summary.academicYear})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        '${((summary.totalPaid / (summary.totalCharged > 0 ? summary.totalCharged : 1)) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: summary.totalCharged > 0
                        ? (summary.totalPaid / summary.totalCharged)
                        : 0,
                    backgroundColor: AppTheme.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isClear ? Colors.green : AppTheme.primary,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.borderSubtle),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            isClear
                                ? 'Fees are up to date'
                                : '${summary.overdueCount} pending vouchers',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 16, color: AppTheme.primary),
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
