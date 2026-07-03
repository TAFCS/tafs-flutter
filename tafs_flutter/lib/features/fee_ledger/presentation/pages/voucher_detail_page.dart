import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../core/widgets/student_profile_card.dart';
import '../../../support_tickets/presentation/pages/ticket_list_page.dart';
import '../../domain/entities/voucher.dart';

class VoucherDetailPage extends StatefulWidget {
  final Voucher voucher;

  const VoucherDetailPage({super.key, required this.voucher});

  @override
  State<VoucherDetailPage> createState() => _VoucherDetailPageState();
}

class _VoucherDetailPageState extends State<VoucherDetailPage> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  Future<void> _openSupportTickets() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TicketListPage(),
      ),
    );
  }

  Future<void> _viewInBrowser() async {
    if (widget.voucher.pdfUrl == null) return;
    final uri = Uri.parse(widget.voucher.pdfUrl!);
    try {
      final launched = kIsWeb
          ? await launchUrl(uri, webOnlyWindowName: '_blank')
          : await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorMapper.fromObject(
              e,
              fallback: 'Could not open the challan. Please try again.',
            )),
          ),
        );
      }
    }
  }

  Future<void> _downloadToDevice() async {
    if (widget.voucher.pdfUrl == null) return;
    if (kIsWeb) {
      final uri = Uri.parse(widget.voucher.pdfUrl!);
      try {
        final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start PDF download.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ApiErrorMapper.fromObject(
                e,
                fallback: 'Download failed. Please try again.',
              )),
            ),
          );
        }
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final fileName = 'Challan_${widget.voucher.id}.pdf';

      final response = await Dio().get<List<int>>(
        widget.voucher.pdfUrl!,
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
      }

      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorMapper.fromObject(
              e,
              fallback: 'Download failed. Please try again.',
            )),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text('Challan #${widget.voucher.id}'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isDownloading)
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppTheme.blue100,
              color: AppTheme.navy,
              minHeight: 3,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StudentProfileCard(),
                  const SizedBox(height: AppTheme.space6),
                  _StatusHeader(voucher: widget.voucher),
                  if (widget.voucher.status == 'EXPIRED') ...[
                    const SizedBox(height: AppTheme.space4),
                    _ExpiredVoucherActions(
                      onContactAdmin: _openSupportTickets,
                    ),
                  ],
                  const SizedBox(height: AppTheme.space6),
                  _SummaryCard(voucher: widget.voucher),
                  const SizedBox(height: AppTheme.space6),
                  if (widget.voucher.bankInfo != null) ...[
                    Text(
                      'PAYMENT INSTRUCTIONS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.blue300,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    _BankDetails(bankInfo: widget.voucher.bankInfo!),
                    const SizedBox(height: AppTheme.space8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.voucher.status == 'EXPIRED'
          ? Container(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space5,
                AppTheme.space4,
                AppTheme.space5,
                MediaQuery.of(context).padding.bottom + AppTheme.space4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.white,
                border: const Border(
                  top: BorderSide(color: AppTheme.blue100, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navy.withValues(alpha: 0.04),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SizedBox(
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.navyGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _openSupportTickets,
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                    label: const Text(
                      'CONTACT ADMIN FOR REPRINT (RS. 100)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppTheme.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
            )
          : widget.voucher.pdfUrl == null
              ? null
              : Container(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space5,
                AppTheme.space4,
                AppTheme.space5,
                MediaQuery.of(context).padding.bottom + AppTheme.space4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.white,
                border: const Border(
                  top: BorderSide(color: AppTheme.blue100, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navy.withOpacity(0.04),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isDownloading ? null : _viewInBrowser,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text(
                          'View',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.navy,
                          side: const BorderSide(color: AppTheme.navy, width: 1.5),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space4),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.navyGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        boxShadow: AppTheme.shadowSm,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadToDevice,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(AppTheme.white),
                                ),
                              )
                            : const Icon(Icons.file_download_outlined, size: 18),
                        label: Text(
                          _isDownloading ? 'Downloading...' : 'Download PDF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppTheme.white,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ExpiredVoucherActions extends StatelessWidget {
  final VoidCallback onContactAdmin;

  const _ExpiredVoucherActions({required this.onContactAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voucher expired',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.danger,
                ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.navy.withValues(alpha: 0.75),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
              children: [
                const TextSpan(
                  text: 'To pay this fee, the voucher must be regenerated by the school.\n'
                      'Reprinting fee: ',
                ),
                TextSpan(
                  text: 'Rs. 100',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.navy.withValues(alpha: 0.85),
                        height: 1.4,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onContactAdmin,
              icon: const Icon(Icons.support_agent_outlined, size: 18),
              label: const Text(
                'Contact admin to regenerate',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.navy,
                side: BorderSide(color: AppTheme.navy.withValues(alpha: 0.6)),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
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
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'OVERDUE':
        statusColor = AppTheme.danger;
        statusIcon = Icons.error_rounded;
        break;
      case 'PARTIALLY_PAID':
        statusColor = AppTheme.warning;
        statusIcon = Icons.timelapse_rounded;
        statusText = 'PARTIAL';
        break;
      case 'VOID':
        statusColor = AppTheme.blue200;
        statusIcon = Icons.cancel_rounded;
        statusText = 'CANCELLED';
        break;
      default:
        statusColor = AppTheme.blue300;
        statusIcon = Icons.receipt_long_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.1), statusColor.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText.replaceAll('_', ' '),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  voucher.status == 'PAID'
                      ? 'Payment fully cleared'
                      : 'Due date: ${dateFmt.format(voucher.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor.withValues(alpha: 0.7),
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
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
        border: Border.all(color: AppTheme.blue100),
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
              value: 'Rs. ${fmt.format(voucher.totalPayableAfterDue - voucher.totalPayableBeforeDue)}',
              color: AppTheme.danger,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.space3),
            child: Divider(color: AppTheme.blue100, height: 1),
          ),
          _SummaryRow(
            label: 'Total Paid',
            value: 'Rs. ${fmt.format(voucher.totalPaid)}',
            color: AppTheme.success,
          ),
          const SizedBox(height: AppTheme.space2),
          _SummaryRow(
            label: 'Outstanding Balance',
            value: 'Rs. ${fmt.format(voucher.totalBalance)}',
            bold: true,
            fontSize: 18,
            color: AppTheme.navy,
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
          Text(label, style: const TextStyle(color: AppTheme.blue300, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.w700,
              color: color ?? AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  final Voucher voucher;
  const _FeeBreakdown({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final heads = voucher.heads;
    final activeSurcharges = voucher.activeArrearSurcharges;
    final itemCount = heads.length + (activeSurcharges.isNotEmpty ? 1 : 0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.blue100),
        itemBuilder: (ctx, i) {
          if (i == heads.length) {
            final totalAmount = activeSurcharges.fold<double>(
              0,
              (s, a) => s + a.amount,
            );
            final totalDeposited = activeSurcharges.fold<double>(
              0,
              (s, a) => s + a.amountPaid,
            );
            final totalBalance = activeSurcharges.fold<double>(
              0,
              (s, a) => s + a.balance,
            );

            return Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Previous Months' Late Payment Surcharge",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Row(
                    children: [
                      Expanded(
                        child: _BreakdownStat(
                          label: 'Net Amount',
                          value: 'Rs. ${fmt.format(totalAmount)}',
                        ),
                      ),
                      Expanded(
                        child: _BreakdownStat(
                          label: 'Deposited',
                          value: 'Rs. ${fmt.format(totalDeposited)}',
                          valueColor: AppTheme.success,
                        ),
                      ),
                      Expanded(
                        child: _BreakdownStat(
                          label: 'Balance',
                          value: 'Rs. ${fmt.format(totalBalance)}',
                          valueColor: totalBalance > 0
                              ? AppTheme.danger
                              : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final head = heads[i];
          return Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (head.isArrear)
                      Container(
                        margin: const EdgeInsets.only(right: AppTheme.space2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'ARREARS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    Text(
                      head.feeType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.navy,
                      ),
                    ),
                  ],
                ),
                if (head.discountAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Discount: ${head.discountLabel ?? "Applied"} (-Rs. ${fmt.format(head.discountAmount)})',
                      style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: AppTheme.space4),
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
                        valueColor: AppTheme.success,
                      ),
                    ),
                    Expanded(
                      child: _BreakdownStat(
                        label: 'Balance',
                        value: 'Rs. ${fmt.format(head.balance)}',
                        valueColor: head.balance > 0
                            ? AppTheme.danger
                            : AppTheme.success,
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
            fontSize: 10,
            color: AppTheme.blue200,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.navy,
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
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 18,
                color: AppTheme.navy,
              ),
              const SizedBox(width: AppTheme.space2),
              Text(
                bankInfo.bankName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          _BankField(label: 'Account Title', value: bankInfo.accountTitle),
          _BankField(
            label: 'Account No.',
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
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.blue300, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navy),
            ),
          ),
          if (canCopy)
            const Icon(Icons.copy_rounded, size: 14, color: AppTheme.blue300),
        ],
      ),
    );
  }
}


