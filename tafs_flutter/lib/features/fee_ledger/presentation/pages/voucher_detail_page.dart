import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/student_profile_card.dart';
import '../../domain/entities/voucher.dart';

class VoucherDetailPage extends StatelessWidget {
  final Voucher voucher;

  const VoucherDetailPage({super.key, required this.voucher});

  void _showChallanOptions(BuildContext context) {
    if (voucher.pdfUrl == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ChallanOptionsSheet(voucherId: voucher.id, pdfUrl: voucher.pdfUrl!),
    );
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
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.primary,
              ),
              tooltip: 'Challan Options',
              onPressed: () => _showChallanOptions(context),
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
          _SummaryRow(
            label: 'Net Amount',
            value: 'Rs. ${fmt.format(voucher.totalPayableBeforeDue)}',
          ),
          if (voucher.lateFeeCharge && voucher.isOverdue)
            _SummaryRow(
              label: 'Late Surcharge',
              value:
                  'Rs. ${fmt.format(voucher.totalPayableAfterDue - voucher.totalPayableBeforeDue)}',
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
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (ctx, i) {
          final head = heads[i];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  head.feeType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
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
        border: Border.all(
          color: AppTheme.borderSubtle,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                bankInfo.bankName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BankField(label: 'Account Title', value: bankInfo.accountTitle),
          _BankField(
            label: 'Account Number',
            value: bankInfo.accountNumber,
            canCopy: true,
          ),
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

  const _BankField({
    required this.label,
    required this.value,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
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

// ─── Challan Options Bottom Sheet ────────────────────────────────────────────
class _ChallanOptionsSheet extends StatefulWidget {
  final int voucherId;
  final String pdfUrl;

  const _ChallanOptionsSheet({required this.voucherId, required this.pdfUrl});

  @override
  State<_ChallanOptionsSheet> createState() => _ChallanOptionsSheetState();
}

class _ChallanOptionsSheetState extends State<_ChallanOptionsSheet> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  Future<void> _viewInBrowser() async {
    Navigator.pop(context);
    final uri = Uri.parse(widget.pdfUrl);
    try {
      final launched = kIsWeb
          ? await launchUrl(uri, webOnlyWindowName: '_blank')
          : await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open browser')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _downloadToDevice() async {
    if (kIsWeb) {
      Navigator.pop(context);
      final uri = Uri.parse(widget.pdfUrl);
      try {
        final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start PDF download.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
        }
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final fileName = 'Challan_${widget.voucherId}.pdf';

      final response = await Dio().get<List<int>>(
        widget.pdfUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Received empty file from server.');
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      String? savedPath;

      if (Platform.isAndroid || Platform.isIOS) {
        savedPath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: tempPath,
            fileName: fileName,
          ),
        );
      } else {
        final downloads = await getDownloadsDirectory();
        final targetDir = downloads ?? await getApplicationDocumentsDirectory();
        savedPath = '${targetDir.path}/$fileName';
        await File(savedPath).writeAsBytes(bytes, flush: true);
      }

      if (savedPath == null) {
        throw Exception('Save cancelled.');
      }

      final finalSavedPath = savedPath;

      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
      });

      if (mounted) {
        final shownPath = finalSavedPath.length > 48
            ? '...${finalSavedPath.substring(finalSavedPath.length - 48)}'
            : finalSavedPath;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $shownPath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                await OpenFilex.open(finalSavedPath);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }

      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.shadowL2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon + Title
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Challan PDF',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'How would you like to open this challan?',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),

          // Download progress
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: AppTheme.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}% downloaded...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

          // Action Buttons
          if (!_isDownloading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // View in Browser
                  Expanded(
                    child: _OptionButton(
                      icon: Icons.open_in_browser_rounded,
                      label: 'View in Browser',
                      subtitle: 'Opens in external app',
                      color: AppTheme.accent,
                      onTap: _viewInBrowser,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Download
                  Expanded(
                    child: _OptionButton(
                      icon: Icons.download_rounded,
                      label: 'Download',
                      subtitle: 'Save to device',
                      color: AppTheme.primary,
                      onTap: _downloadToDevice,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
