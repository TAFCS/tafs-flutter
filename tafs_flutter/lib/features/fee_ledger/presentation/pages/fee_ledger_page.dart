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
import '../utils/voucher_display.dart';
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
  bool _autoReloadScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  @override
  void didUpdateWidget(covariant FeeLedgerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentCc != widget.studentCc) {
      _loadFees();
    }
  }

  void _loadFees() {
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
              onRetry: _loadFees,
            );
          }

          if (state is FeeLedgerLoaded) {
            final months = state.months;
            final visibleVouchers = VoucherDisplay.visibleVouchers(state.vouchers);
            final activeVouchers = visibleVouchers.where((v) => v.status != 'PAID').toList();
            final paidVouchers = visibleVouchers.where((v) => v.status == 'PAID').toList();
            final totalOutstanding =
                VoucherDisplay.outstandingTotal(state.vouchers);

            if (months.isEmpty && visibleVouchers.isEmpty) {
              return const _NoMonthsView();
            }

            return Column(
              children: [
                if (widget.showAppBar)
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.space4),
                    child: StudentProfileCard(),
                  ),
                _SummaryStrip(
                  totalOutstanding: totalOutstanding,
                  runningOutstanding: totalOutstanding,
                  monthsCount: months.length,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadFees();
                    },
                    child: visibleVouchers.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppTheme.space4),
                            children: const [
                              _AllCaughtUpCard(),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppTheme.space4),
                            children: [
                              if (totalOutstanding <= 0 && activeVouchers.isEmpty) ...[
                                const _AllCaughtUpCard(),
                                const SizedBox(height: AppTheme.space6),
                              ],
                              if (activeVouchers.isNotEmpty) ...[
                                Text(
                                  'ACTIVE CHALLAN',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppTheme.blue300,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space3),
                                ...activeVouchers.map(
                                  (voucher) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.space4),
                                    child: _ActiveVoucherCard(voucher: voucher),
                                  ),
                                ),
                              ],
                              if (paidVouchers.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.space4),
                                Text(
                                  'PAYMENT HISTORY',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppTheme.blue300,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space3),
                                ...paidVouchers.map(
                                  (voucher) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.space3),
                                    child: _HistoryVoucherCard(voucher: voucher),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            );
          }

          if (!_autoReloadScheduled) {
            _autoReloadScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _autoReloadScheduled = false;
              if (mounted) _loadFees();
            });
          }
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.navy),
          );
        },
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final double totalOutstanding;
  final double runningOutstanding;
  final int monthsCount;

  const _SummaryStrip({
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
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('VIEW CHALLAN'),
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
              itemCount: VoucherDisplay.visibleVouchers(vouchers).length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space3),
              itemBuilder: (_, i) {
                final voucher = VoucherDisplay.visibleVouchers(vouchers)[i];
                return voucher.status == 'PAID'
                    ? _HistoryVoucherCard(voucher: voucher)
                    : _ActiveVoucherCard(voucher: voucher);
              },
            ),
    );
  }
}

class _ActiveVoucherCard extends StatelessWidget {
  final Voucher voucher;

  const _ActiveVoucherCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final statusColor = VoucherDisplay.statusColor(voucher);
    final amount = VoucherDisplay.displayAmount(voucher);
    final subtitle = VoucherDisplay.subtitle(voucher);
    final footer = VoucherDisplay.footer(voucher);
    final canOpen = VoucherDisplay.canOpenDetail(voucher);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: voucher.status == 'EXPIRED'
              ? AppTheme.danger.withValues(alpha: 0.25)
              : AppTheme.blue100,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.18),
                      statusColor.withOpacity(0.0),
                    ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        VoucherDisplay.title(voucher),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space2,
                          vertical: AppTheme.space1,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          VoucherDisplay.statusLabel(voucher).toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space1),
                  Text(
                    'Challan #${voucher.id}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.blue300,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (amount != null) ...[
                    const SizedBox(height: AppTheme.space3),
                    Text(
                      'Rs. ${fmt.format(amount)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTheme.space2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.blue300),
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.blue300,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: AppTheme.space3),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.space3),
                      decoration: BoxDecoration(
                        color: voucher.status == 'EXPIRED'
                            ? AppTheme.danger.withValues(alpha: 0.06)
                            : AppTheme.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: voucher.status == 'EXPIRED'
                              ? AppTheme.danger.withValues(alpha: 0.15)
                              : AppTheme.warning.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        footer,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.navy.withValues(alpha: 0.75),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                  if (canOpen) ...[
                    const SizedBox(height: AppTheme.space5),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.navyGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VoucherDetailPage(voucher: voucher),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text(
                            'VIEW CHALLAN',
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryVoucherCard extends StatelessWidget {
  final Voucher voucher;

  const _HistoryVoucherCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final statusColor = VoucherDisplay.statusColor(voucher);
    final amount = VoucherDisplay.displayAmount(voucher);
    final subtitle = VoucherDisplay.subtitle(voucher);
    final canOpen = VoucherDisplay.canOpenDetail(voucher);

    return InkWell(
      onTap: canOpen
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoucherDetailPage(voucher: voucher),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.blue100),
          boxShadow: AppTheme.shadowSm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.12),
                        statusColor.withOpacity(0.0),
                      ],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space4,
                  vertical: AppTheme.space3 * 1.2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CHALLAN #${voucher.id}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.navy,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Text(
                                  VoucherDisplay.statusLabel(voucher).toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space2),
                          if (amount != null)
                            Text(
                              'Rs. ${fmt.format(amount)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navy,
                                  ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.blue300,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canOpen)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.blue300,
                        size: 20,
                      ),
                  ],
                ),
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

class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space3),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 36),
          ),
          const SizedBox(height: AppTheme.space4),
          const Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "No outstanding fees for this student.",
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.blue300,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

