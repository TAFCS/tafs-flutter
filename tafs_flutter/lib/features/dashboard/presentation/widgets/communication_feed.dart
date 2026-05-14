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

          final outstanding = vouchers.where((v) => 
            v.status == 'ISSUED' || v.status == 'PARTIALLY_PAID'
          ).toList();

          outstanding.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final now = DateTime.now();

          for (final voucher in outstanding) {
            final isOverdue = now.isAfter(voucher.dueDate);
            final daysUntilDue = voucher.dueDate.difference(now).inDays;
            final monthLabel = _getMonthLabel(voucher.month);

            if (isOverdue) {
              notifications.add(
                _buildAlertCard(
                  context: context,
                  title: 'Overdue Fee: $monthLabel',
                  message: 'Challan #${voucher.id} was due on ${DateFormat('MMM dd').format(voucher.dueDate)}. Outstanding: Rs. ${NumberFormat('#,###').format(voucher.totalBalance)}.',
                  icon: Icons.error_outline_rounded,
                  color: AppTheme.danger,
                ),
              );
            } else if (daysUntilDue <= 7) {
              notifications.add(
                _buildAlertCard(
                  context: context,
                  title: 'Upcoming Due Date: $monthLabel',
                  message: 'Challan #${voucher.id} is due in ${daysUntilDue == 0 ? "today" : "$daysUntilDue days"}. Avoid late fees by paying before ${DateFormat('MMM dd').format(voucher.dueDate)}.',
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.warning,
                ),
              );
            }
          }

          if (notifications.isEmpty) {
            notifications.add(
              _buildAlertCard(
                context: context,
                title: 'No Pending Actions',
                message: 'Your account is currently in good standing. No unpaid vouchers found.',
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.success,
              ),
            );
          }
        } else if (state is FeeLedgerLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.space8),
              child: CircularProgressIndicator(color: AppTheme.navy, strokeWidth: 2),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppTheme.navy, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Priority Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.navy),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            if (notifications.isNotEmpty)
              ...notifications.expand((n) => [n, const SizedBox(height: AppTheme.space3)])
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
                child: Text(
                  'No priority updates for now.',
                  style: TextStyle(color: AppTheme.blue300, fontSize: 13),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getMonthLabel(int? month) {
    if (month == null || month < 1 || month > 12) return 'Cycle';
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${labels[month - 1]} Cycle';
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100),
        boxShadow: AppTheme.shadowXs,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navy),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              style: TextStyle(color: AppTheme.blue300, fontSize: 12, height: 1.4),
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
