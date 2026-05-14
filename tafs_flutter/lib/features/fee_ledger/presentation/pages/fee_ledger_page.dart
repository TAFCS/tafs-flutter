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
  final bool showAppBar;

  const FeeLedgerPage({
    super.key,
    required this.studentCc,
    required this.studentName,
    this.showAppBar = true,
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
      backgroundColor: AppTheme.white,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Fee Ledger'),
              backgroundColor: AppTheme.white,
              foregroundColor: AppTheme.navy,
              elevation: 0,
            )
          : null,
      body: BlocBuilder<FeeLedgerBloc, FeeLedgerState>(
        builder: (context, state) {
          if (state is FeeLedgerLoading || state is FeeLedgerInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.navy),
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
                if (widget.showAppBar)
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.space4),
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
                      padding: const EdgeInsets.all(AppTheme.space4),
                      itemCount: months.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space3),
                      itemBuilder: (context, index) {
                        final month = months[index];
                        final monthVouchers = vouchers.where((v) {
                          final belongsToMonth = v.heads.any(
                            (h) =>
                                h.academicYear == month.academicYear &&
                                h.targetMonth == month.targetMonth &&
                                !h.isArrear,
                          );

                          if (!belongsToMonth) return false;
                          if (v.status == 'VOID') {
                            return v.totalPaid > 0;
                          }
                          return true;
                        }).toList();

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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6, vertical: AppTheme.space5),
      decoration: const BoxDecoration(
        gradient: AppTheme.navyGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STUDENT FEE SUMMARY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            'Rs. ${fmt.format(totalOutstanding)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'Total Outstanding Balance',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.white.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: AppTheme.space5),
          Row(
            children: [
              _StatPill(label: 'Charged', value: fmt.format(totalCharged)),
              const SizedBox(width: AppTheme.space2),
              _StatPill(
                label: 'Paid',
                value: fmt.format(totalPaid),
                isSuccess: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isSuccess;

  const _StatPill({
    required this.label,
    required this.value,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3, vertical: AppTheme.space1),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppTheme.success.withValues(alpha: 0.2)
            : AppTheme.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: isSuccess 
              ? AppTheme.success.withValues(alpha: 0.3) 
              : AppTheme.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: isSuccess ? AppTheme.white : AppTheme.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'Rs. $value',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'PAID':
        return AppTheme.successGradient;
      case 'PARTIALLY_PAID':
        return AppTheme.warningGradient;
      case 'NOT_ISSUED':
        return LinearGradient(colors: [AppTheme.blue300, AppTheme.blue200]);
      default:
        return AppTheme.dangerGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final statusGradient = _statusGradient(month.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.blue100),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${month.monthLabel} ${month.academicYear}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space2,
                      vertical: AppTheme.space1,
                    ),
                    decoration: BoxDecoration(
                      gradient: statusGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: statusGradient.colors.first.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      month.status.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(
                    label: 'CHALLAN AMOUNT',
                    value: 'Rs. ${fmt.format((month.voucherTotal ?? 0) > 0 ? month.voucherTotal! : month.totalAmount)}',
                  ),
                  _Metric(
                    label: 'PAID',
                    value: 'Rs. ${fmt.format(month.totalPaid)}',
                    valueColor: AppTheme.success,
                  ),
                  _Metric(
                    label: 'OUTSTANDING',
                    value: 'Rs. ${fmt.format((month.voucherTotal ?? 0) > 0 ? (month.voucherTotal! - month.totalPaid) : month.outstandingBalance)}',
                    valueColor: (month.voucherTotal ?? month.outstandingBalance) > 0 ? AppTheme.danger : AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space4),
              const Divider(color: AppTheme.blue100),
              const SizedBox(height: AppTheme.space2),
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 14,
                    color: AppTheme.blue300,
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Text(
                    '$challanCount Linked Challans',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.blue300,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.navy,
                    size: 12,
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.blue200,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.navy,
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
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text('${month.monthLabel} ${month.academicYear}'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space5),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.blue100),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Month Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.space4),
                _DetailRow('Status', month.status.replaceAll('_', ' ')),
                _DetailRow(
                    'Challan Total',
                    'Rs. ${fmt.format((month.voucherTotal ?? 0) > 0 ? month.voucherTotal! : month.totalAmount)}',
                  ),
                _DetailRow('Paid', 'Rs. ${fmt.format(month.totalPaid)}'),
                _DetailRow(
                  'Outstanding',
                  'Rs. ${fmt.format((month.voucherTotal ?? 0) > 0 ? (month.voucherTotal! - month.totalPaid) : month.outstandingBalance)}',
                ),
                _DetailRow(
                  'Running Balance',
                  'Rs. ${fmt.format(month.runningOutstandingBalance)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          if (month.status != 'PAID') ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.navyGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _resolveAndOpen(context),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('DOWNLOAD CHALLAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space3),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _resolveAndOpen(context),
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('PAY NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space3),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
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
              label: const Text('View Challan History'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.navy),
                foregroundColor: AppTheme.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.blue300)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.bold,
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
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: vouchers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppTheme.blue100),
                  const SizedBox(height: AppTheme.space3),
                  Text(
                    'No challan history found.',
                    style: TextStyle(color: AppTheme.blue300, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTheme.space4),
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space3),
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
        return AppTheme.success;
      case 'OVERDUE':
        return AppTheme.danger;
      case 'PARTIALLY_PAID':
        return AppTheme.warning;
      case 'VOID':
        return AppTheme.blue200;
      default:
        return AppTheme.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoucherDetailPage(voucher: voucher),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.blue100),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'CHALLAN #${voucher.id}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space2,
                      vertical: AppTheme.space1,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      voucher.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rs. ${fmt.format(voucher.totalPayableBeforeDue)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Due: ${dateFmt.format(voucher.dueDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.blue300),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.blue100),
                ],
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
            color: AppTheme.blue100,
          ),
          const SizedBox(height: AppTheme.space3),
          Text(
            'No fee records found',
            style: TextStyle(color: AppTheme.blue300, fontSize: 16),
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
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 64),
            const SizedBox(height: AppTheme.space4),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.blue300),
            ),
            const SizedBox(height: AppTheme.space5),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
