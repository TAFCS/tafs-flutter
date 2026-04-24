import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../../fee_ledger/presentation/bloc/fee_ledger_state.dart';
import '../../../fee_ledger/domain/entities/voucher.dart';
import 'package:intl/intl.dart';

class CommunicationFeed extends StatelessWidget {
  const CommunicationFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeeLedgerBloc, FeeLedgerState>(
      builder: (context, state) {
        List<Widget> notifications = [];

        if (state is FeeLedgerLoaded || state is LedgerLoaded) {
          final List<Voucher> vouchers = (state is FeeLedgerLoaded) 
              ? state.vouchers 
              : (state as LedgerLoaded).vouchers;

          // Filter for outstanding vouchers (ISSUED or PARTIALLY_PAID)
          final outstanding = vouchers.where((v) => 
            v.status == 'ISSUED' || v.status == 'PARTIALLY_PAID'
          ).toList();

          // Sort by due date (soonest first)
          outstanding.sort((a, b) => a.dueDate.compareTo(b.dueDate));

          final now = DateTime.now();

          for (final voucher in outstanding) {
            final isOverdue = now.isAfter(voucher.dueDate);
            final daysUntilDue = voucher.dueDate.difference(now).inDays;
            final monthLabel = _getMonthLabel(voucher.month);

            if (isOverdue) {
              notifications.add(
                _buildAlertCard(
                  title: 'Overdue Fee: $monthLabel',
                  message: 'Challan #${voucher.id} was due on ${DateFormat('MMM dd').format(voucher.dueDate)}. Please clear your balance of Rs. ${NumberFormat('#,###').format(voucher.totalBalance)} as soon as possible.',
                  icon: Icons.error_outline_rounded,
                  color: Colors.red,
                ),
              );
            } else if (daysUntilDue <= 7) {
              notifications.add(
                _buildAlertCard(
                  title: 'Fee Reminder: $monthLabel',
                  message: 'Challan #${voucher.id} is due in ${daysUntilDue == 0 ? "today" : "$daysUntilDue days"} (${DateFormat('MMM dd').format(voucher.dueDate)}). Avoid late fees by paying on time.',
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.accent,
                ),
              );
            }
          }

          // If no critical alerts, show a welcome or status message
          if (notifications.isEmpty) {
            notifications.add(
              _buildAlertCard(
                title: 'All Caught Up!',
                message: 'You have no pending fee actions at this time. All clear!',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
            );
          }
        } else if (state is FeeLedgerLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          );
        }

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
            if (notifications.isNotEmpty)
              ...notifications.expand((n) => [n, const SizedBox(height: 12)])
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No new notifications.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getMonthLabel(int? month) {
    if (month == null || month < 1 || month > 12) return 'Cycle';
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${labels[month - 1]} Cycle';
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
