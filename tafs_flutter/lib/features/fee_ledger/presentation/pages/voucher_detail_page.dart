import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/student_profile_card.dart';
import '../../domain/entities/voucher.dart';

class VoucherDetailPage extends StatelessWidget {
  final Voucher voucher;

  const VoucherDetailPage({super.key, required this.voucher});

  Future<void> _launchPdf(BuildContext context) async {
    if (voucher.pdfUrl == null) return;
    final uri = Uri.parse(voucher.pdfUrl!);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch PDF viewer')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Challan #${voucher.id}'),
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
        actions: [
          if (voucher.pdfUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
              onPressed: () => _launchPdf(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Header
            const StudentProfileCard(),
            const SizedBox(height: 24),

            // Status Header
            _StatusHeader(voucher: voucher),
            const SizedBox(height: 24),

            // Summary Card
            _SummaryCard(voucher: voucher),
            const SizedBox(height: 24),

            // Fee Items
            const Text(
              'Fee Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 12),
            _FeeBreakdown(heads: voucher.heads),
            const SizedBox(height: 24),

            // Bank Details
            if (voucher.bankInfo != null) ...[
              const Text(
                'Payment Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 12),
              _BankDetails(bankInfo: voucher.bankInfo!),
              const SizedBox(height: 32),
            ],

            // Action Buttons
            if (voucher.status != 'PAID')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement Payment Integration
                  },
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('Pay Now / Generate ID'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final Voucher voucher;
  const _StatusHeader({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    Color statusColor;
    IconData statusIcon;
    String statusText = voucher.status;

    switch (voucher.status) {
      case 'PAID':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'OVERDUE':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case 'PARTIALLY_PAID':
        statusColor = Colors.orange;
        statusIcon = Icons.timelapse_rounded;
        statusText = 'Partial';
        break;
      default:
        statusColor = AppTheme.accent;
        statusIcon = Icons.receipt_long_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voucher.status == 'PAID'
                      ? 'Fully cleared'
                      : 'Due by ${dateFmt.format(voucher.dueDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
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

class _SummaryCard extends StatelessWidget {
  final Voucher voucher;
  const _SummaryCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.shadowL1,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Net Amount', value: 'Rs. ${fmt.format(voucher.totalPayableBeforeDue)}'),
          if (voucher.lateFeeCharge && voucher.isOverdue)
            _SummaryRow(
              label: 'Late Surcharge',
              value: 'Rs. ${fmt.format(voucher.totalPayableAfterDue - voucher.totalPayableBeforeDue)}',
              color: Colors.red,
            ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Total Paid',
            value: 'Rs. ${fmt.format(voucher.totalPaid)}',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Outstanding Balance',
            value: 'Rs. ${fmt.format(voucher.totalBalance)}',
            bold: true,
            fontSize: 18,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  final double fontSize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
    this.fontSize = 14,
  });

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
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  final List<VoucherHead> heads;
  const _FeeBreakdown({required this.heads});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: heads.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (ctx, i) {
          final head = heads[i];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  head.feeType,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (head.discountAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Discount: ${head.discountLabel ?? "Applied"} (-Rs. ${fmt.format(head.discountAmount)})',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BreakdownStat(
                        label: 'Net Amount',
                        value: 'Rs. ${fmt.format(head.netAmount)}',
                      ),
                    ),
                    Expanded(
                      child: _BreakdownStat(
                        label: 'Deposited',
                        value: 'Rs. ${fmt.format(head.amountDeposited)}',
                        valueColor: Colors.green.shade700,
                      ),
                    ),
                    Expanded(
                      child: _BreakdownStat(
                        label: 'Balance',
                        value: 'Rs. ${fmt.format(head.balance)}',
                        valueColor: head.balance > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BreakdownStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}

class _BankDetails extends StatelessWidget {
  final BankInfo bankInfo;
  const _BankDetails({required this.bankInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                bankInfo.bankName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BankField(label: 'Account Title', value: bankInfo.accountTitle),
          _BankField(label: 'Account Number', value: bankInfo.accountNumber, canCopy: true),
          if (bankInfo.iban != null)
            _BankField(label: 'IBAN', value: bankInfo.iban!, canCopy: true),
        ],
      ),
    );
  }
}

class _BankField extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _BankField({required this.label, required this.value, this.canCopy = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (canCopy)
            const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
        ],
      ),
    );
  }
}
