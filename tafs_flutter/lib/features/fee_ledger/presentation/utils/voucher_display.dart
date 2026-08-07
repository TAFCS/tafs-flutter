import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/voucher.dart';

/// APP-01 parent-facing voucher display rules (excludes VOID).
class VoucherDisplay {
  VoucherDisplay._();

  static const expiredRegenerationNote =
      'Contact the school admin to regenerate this voucher. '
      'A regenerated voucher carries a Rs. 100 reprinting fee.';

  static List<Voucher> visibleVouchers(Iterable<Voucher> vouchers) {
    return vouchers
        .where((v) => v.status != 'VOID')
        .toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  static double outstandingTotal(Iterable<Voucher> vouchers) {
    return visibleVouchers(vouchers)
        .where((v) => _isOutstanding(v.status))
        .fold(0.0, (sum, v) => sum + v.totalBalance);
  }

  static bool _isOutstanding(String status) =>
      status == 'UNPAID' ||
      status == 'OVERDUE' ||
      status == 'PARTIALLY_PAID';

  /// Caption shown above the months on a voucher card, matching the challan's
  /// "FOR MONTH(S) OF" heading.
  static const forMonthsOfLabel = 'For the month(s) of';

  /// Every month this voucher bills, consolidated into ranges — e.g.
  /// "AUG 25 - OCT 25, JAN 26".
  ///
  /// Built server-side (vouchers.months_label) from the billed fee rows, so it
  /// always matches the challan PDF. Falls back to the voucher's own header
  /// month only for payloads issued before that field existed: that column
  /// names at most one month of a multi-month voucher, which is exactly what
  /// made this label wrong.
  static String monthsLabel(Voucher voucher) {
    final label = voucher.monthsLabel?.trim();
    if (label != null && label.isNotEmpty && label != 'N/A') return label;
    return _headerMonthLabel(voucher);
  }

  static String _headerMonthLabel(Voucher voucher) {
    if (voucher.month != null && voucher.month! >= 1 && voucher.month! <= 12) {
      return DateFormat('MMMM').format(DateTime(2000, voucher.month!, 1));
    }
    return 'Fee';
  }

  static String title(Voucher voucher) {
    final label = voucher.monthsLabel?.trim();
    // The server label already carries its own year(s) ("AUG 25 - OCT 25");
    // appending academicYear on top would read as a contradiction.
    if (label != null && label.isNotEmpty && label != 'N/A') return label;

    final fallback = _headerMonthLabel(voucher);
    if (voucher.academicYear != null && voucher.academicYear!.isNotEmpty) {
      return '$fallback ${voucher.academicYear}';
    }
    return fallback;
  }

  static String statusLabel(Voucher voucher) {
    switch (voucher.status) {
      case 'PAID':
        return 'Paid';
      case 'OVERDUE':
        return 'Overdue';
      case 'EXPIRED':
        return 'Expired';
      case 'PARTIALLY_PAID':
        return 'Partially Paid';
      default:
        return 'Unpaid';
    }
  }

  static Color statusColor(Voucher voucher) {
    switch (voucher.status) {
      case 'PAID':
        return AppTheme.success;
      case 'OVERDUE':
      case 'EXPIRED':
        return AppTheme.danger;
      case 'PARTIALLY_PAID':
        return AppTheme.warning;
      default:
        return AppTheme.navy;
    }
  }

  /// Amount shown on the card per APP-01.
  static double? displayAmount(Voucher voucher) {
    switch (voucher.status) {
      case 'PAID':
      case 'UNPAID':
      case 'PARTIALLY_PAID':
        return voucher.totalPayableBeforeDue;
      case 'OVERDUE':
        return voucher.totalPayableAfterDue;
      case 'EXPIRED':
        return null;
      default:
        return voucher.totalPayableBeforeDue;
    }
  }

  static String? subtitle(Voucher voucher) {
    final dateFmt = DateFormat('dd MMM yyyy');

    switch (voucher.status) {
      case 'UNPAID':
      case 'PARTIALLY_PAID':
        return 'Due ${dateFmt.format(voucher.dueDate)}';
      case 'PAID':
        return 'Paid in full';
      case 'OVERDUE':
        if (voucher.validityDate != null) {
          return 'Valid until ${dateFmt.format(voucher.validityDate!)}';
        }
        return 'Due ${dateFmt.format(voucher.dueDate)}';
      case 'EXPIRED':
        final expiry = voucher.validityDate ?? voucher.dueDate;
        return 'Expired on ${dateFmt.format(expiry)}';
      default:
        return null;
    }
  }

  static String? footer(Voucher voucher) {
    switch (voucher.status) {
      case 'OVERDUE':
        if (voucher.validityDate == null) return null;
        final dateFmt = DateFormat('dd MMM yyyy');
        return 'Please pay before ${dateFmt.format(voucher.validityDate!)} '
            'or this voucher will expire.';
      case 'EXPIRED':
        return expiredRegenerationNote;
      default:
        return null;
    }
  }

  static bool canOpenDetail(Voucher voucher) => true;
}
