import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/student_profile_card.dart';
import '../../domain/entities/fee_month_status.dart';
import '../../domain/entities/voucher.dart';
import '../bloc/fee_ledger_bloc.dart';
import '../bloc/fee_ledger_event.dart';
import '../bloc/fee_ledger_state.dart';
import 'voucher_detail_page.dart';

class FeeLedgerPage extends StatefulWidget {
  final int studentCc;
  final String studentName;

  const FeeLedgerPage({
    super.key,
    required this.studentCc,
    required this.studentName,
  });

  @override
  State<FeeLedgerPage> createState() => _FeeLedgerPageState();
}

class _FeeLedgerPageState extends State<FeeLedgerPage> {
  @override
  void initState() {
    super.initState();
    context.read<FeeLedgerBloc>().add(FeeLedgerLoadRequested(widget.studentCc));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Fee Ledger',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
      ),
      body: BlocBuilder<FeeLedgerBloc, FeeLedgerState>(
        builder: (context, state) {
          if (state is FeeLedgerLoading || state is FeeLedgerInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (state is FeeLedgerError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<FeeLedgerBloc>().add(
                FeeLedgerLoadRequested(widget.studentCc),
              ),
            );
          }

          if (state is FeeLedgerLoaded) {
            final months = state.months;
            final vouchers = state.vouchers;

            if (months.isEmpty) {
              return const _NoMonthsView();
            }

            final totalCharged = months.fold<double>(
              0,
              (s, m) => s + m.totalAmount,
            );
            final totalPaid = months.fold<double>(0, (s, m) => s + m.totalPaid);
            final totalOutstanding = months.fold<double>(
              0,
              (s, m) => s + m.outstandingBalance,
            );
            final runningOutstanding = months.last.runningOutstandingBalance;

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: StudentProfileCard(),
                ),
                _SummaryStrip(
                  totalCharged: totalCharged,
                  totalPaid: totalPaid,
                  totalOutstanding: totalOutstanding,
                  runningOutstanding: runningOutstanding,
                  monthsCount: months.length,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<FeeLedgerBloc>().add(
                        FeeLedgerLoadRequested(widget.studentCc),
                      );
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: months.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final month = months[index];
                        final monthVouchers = vouchers
                            .where(
                              (v) {
                                final directMatch =
                                    v.academicYear == month.academicYear &&
                                    v.month == month.targetMonth;

                                if (directMatch) return true;

                                return v.heads.any(
                                  (h) =>
                                      h.academicYear == month.academicYear &&
                                      h.targetMonth == month.targetMonth,
                                );
                              },
                            )
                            .toList();

                        return _MonthCard(
                          month: month,
                          challanCount: monthVouchers.length,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _FeeMonthDetailPage(
                                  studentCc: widget.studentCc,
                                  month: month,
                                  vouchers: monthVouchers,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final double totalCharged;
  final double totalPaid;
  final double totalOutstanding;
  final double runningOutstanding;
  final int monthsCount;

  const _SummaryStrip({
    required this.totalCharged,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.runningOutstanding,
    required this.monthsCount,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1B436D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Fee Status (Month-Wise)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Outstanding: Rs. ${fmt.format(totalOutstanding)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatPill(label: 'Months', value: '$monthsCount'),
              const SizedBox(width: 8),
              _StatPill(label: 'Charged', value: fmt.format(totalCharged)),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Paid',
                value: fmt.format(totalPaid),
                green: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Running outstanding total: Rs. ${fmt.format(runningOutstanding)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool green;

  const _StatPill({
    required this.label,
    required this.value,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: green
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: green ? Colors.greenAccent : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final FeeMonthStatus month;
  final int challanCount;
  final VoidCallback onTap;

  const _MonthCard({
    required this.month,
    required this.challanCount,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return Colors.green;
      case 'PARTIALLY_PAID':
        return Colors.orange;
      case 'NOT_ISSUED':
        return Colors.blueGrey;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final statusColor = _statusColor(month.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: AppTheme.shadowL1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${month.monthLabel} • ${month.academicYear}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      month.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _Metric(
                    label: 'Month Total',
                    value: 'Rs. ${fmt.format(month.totalAmount)}',
                  ),
                  _Metric(
                    label: 'Paid',
                    value: 'Rs. ${fmt.format(month.totalPaid)}',
                    valueColor: Colors.green,
                  ),
                  _Metric(
                    label: 'Outstanding',
                    value: 'Rs. ${fmt.format(month.outstandingBalance)}',
                    valueColor: month.outstandingBalance > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                  _Metric(
                    label: 'Running Total',
                    value: 'Rs. ${fmt.format(month.runningOutstandingBalance)}',
                    valueColor: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$challanCount challan(s) linked',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.primary,
                    size: 18,
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Metric({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}

class _FeeMonthDetailPage extends StatelessWidget {
  final int studentCc;
  final FeeMonthStatus month;
  final List<Voucher> vouchers;

  const _FeeMonthDetailPage({
    required this.studentCc,
    required this.month,
    required this.vouchers,
  });

  static const _missingVoucherMessage =
      'Challan not yet generated — please contact the school office.';

  Future<void> _resolveAndOpen(BuildContext context) async {
    final result = await context.read<FeeLedgerBloc>().resolveVoucherForMonth(
      studentCc: studentCc,
      academicYear: month.academicYear,
      targetMonth: month.targetMonth,
    );

    if (!context.mounted) return;

    if (!result.exists || result.voucher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message?.trim().isNotEmpty == true
                ? result.message!
                : _missingVoucherMessage,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoucherDetailPage(voucher: result.voucher!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${month.monthLabel} • ${month.academicYear}'),
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Month Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow('Status', month.status.replaceAll('_', ' ')),
                _DetailRow(
                  'Month Total',
                  'Rs. ${fmt.format(month.totalAmount)}',
                ),
                _DetailRow('Paid', 'Rs. ${fmt.format(month.totalPaid)}'),
                _DetailRow(
                  'Outstanding',
                  'Rs. ${fmt.format(month.outstandingBalance)}',
                ),
                _DetailRow(
                  'Running Outstanding',
                  'Rs. ${fmt.format(month.runningOutstandingBalance)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _resolveAndOpen(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Download Challan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _resolveAndOpen(context),
            icon: const Icon(Icons.payment_rounded),
            label: const Text('Pay Now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _VoucherHistoryPage(
                    title: 'Challan History • ${month.monthLabel}',
                    vouchers: vouchers,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
            label: const Text('View Voucher History'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherHistoryPage extends StatelessWidget {
  final String title;
  final List<Voucher> vouchers;

  const _VoucherHistoryPage({required this.title, required this.vouchers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
      ),
      body: vouchers.isEmpty
          ? Center(
              child: Text(
                'No challans available for this period.',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _VoucherCard(voucher: vouchers[i]),
            ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;

  const _VoucherCard({required this.voucher});

  Color get _statusColor {
    switch (voucher.status) {
      case 'PAID':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      case 'PARTIALLY_PAID':
        return Colors.orange;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoucherDetailPage(voucher: voucher),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: AppTheme.shadowL1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Challan #${voucher.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      voucher.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Net: Rs. ${fmt.format(voucher.totalPayableBeforeDue)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Balance: Rs. ${fmt.format(voucher.totalBalance)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: voucher.totalBalance > 0 ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Due: ${dateFmt.format(voucher.dueDate)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMonthsView extends StatelessWidget {
  const _NoMonthsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: AppTheme.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          const Text(
            'No month-wise fee records found',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
