import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/student_profile_card.dart';
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

class _FeeLedgerPageState extends State<FeeLedgerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _tabs = const ['All', 'Unpaid', 'Partial', 'Paid'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    context.read<FeeLedgerBloc>().add(FeeLedgerLoadRequested(widget.studentCc));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Voucher> _filter(List<Voucher> all, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return all.where((v) => v.status == 'UNPAID').toList();
      case 2:
        return all.where((v) => v.status == 'PARTIALLY_PAID').toList();
      case 3:
        return all.where((v) => v.status == 'PAID').toList();
      default:
        return all;
    }
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
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
              onRetry: () => context
                  .read<FeeLedgerBloc>()
                  .add(FeeLedgerLoadRequested(widget.studentCc)),
            );
          }
          if (state is FeeLedgerLoaded) {
            final vouchers = state.vouchers;

            // ── Summary strip ───────────────────────────────────────────────
            final totalOut = vouchers
                .where((v) => v.status != 'PAID')
                .fold(0.0, (s, v) => s + v.totalBalance);
            final paidCount = vouchers.where((v) => v.status == 'PAID').length;

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: StudentProfileCard(),
                ),
                _SummaryStrip(
                  totalOutstanding: totalOut,
                  totalChallans: vouchers.length,
                  paidCount: paidCount,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs.asMap().entries.map((entry) {
                      final filtered = _filter(vouchers, entry.key);
                      if (filtered.isEmpty) {
                        return _EmptyTab(tab: _tabs[entry.key]);
                      }
                      return _VoucherList(vouchers: filtered);
                    }).toList(),
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

// ─── Summary Strip ──────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final double totalOutstanding;
  final int totalChallans;
  final int paidCount;

  const _SummaryStrip({
    required this.totalOutstanding,
    required this.totalChallans,
    required this.paidCount,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Outstanding',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${fmt.format(totalOutstanding)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatPill(label: 'Total', value: '$totalChallans'),
              const SizedBox(height: 6),
              _StatPill(label: 'Paid', value: '$paidCount', green: true),
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
  final bool green;
  const _StatPill({required this.label, required this.value, this.green = false});

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
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Voucher List ───────────────────────────────────────────────────────────

class _VoucherList extends StatelessWidget {
  final List<Voucher> vouchers;
  const _VoucherList({required this.vouchers});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _VoucherCard(voucher: vouchers[i]),
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

  IconData get _statusIcon {
    switch (voucher.status) {
      case 'PAID':
        return Icons.check_circle_rounded;
      case 'OVERDUE':
        return Icons.warning_rounded;
      case 'PARTIALLY_PAID':
        return Icons.timelapse_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoucherDetailPage(voucher: voucher),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: AppTheme.shadowL1,
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_statusIcon, color: _statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.academicYear != null
                              ? 'Challan #${voucher.id} — ${voucher.academicYear}'
                              : 'Challan #${voucher.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voucher.className ?? voucher.campusName ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: voucher.status, color: _statusColor),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            // Amounts row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _AmountTile(
                    label: 'Total Due',
                    value: 'Rs. ${fmt.format(voucher.totalPayableBeforeDue)}',
                    bold: true,
                  ),
                  const SizedBox(width: 20),
                  _AmountTile(
                    label: 'Balance',
                    value: 'Rs. ${fmt.format(voucher.totalBalance)}',
                    color: voucher.totalBalance > 0
                        ? Colors.red.shade700
                        : Colors.green,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Due: ${dateFmt.format(voucher.dueDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: voucher.isOverdue
                              ? Colors.red
                              : AppTheme.textMuted,
                          fontWeight: voucher.isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Issued: ${dateFmt.format(voucher.issueDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // View detail chevron
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  String get _label {
    switch (status) {
      case 'PARTIALLY_PAID':
        return 'Partial';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _AmountTile(
      {required this.label, required this.value, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}

// ─── Empty & Error ──────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final String tab;
  const _EmptyTab({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No $tab challans',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
