import 'package:equatable/equatable.dart';

class VoucherHead extends Equatable {
  final int id;
  final String feeType;
  final double netAmount;
  final double amountDeposited;
  final double balance;
  final String? discountLabel;
  final double discountAmount;
  final String? academicYear;
  final int? targetMonth;

  final bool isArrear;
  final bool isSurcharge;

  const VoucherHead({
    required this.id,
    required this.feeType,
    required this.netAmount,
    required this.amountDeposited,
    required this.balance,
    this.discountLabel,
    required this.discountAmount,
    this.academicYear,
    this.targetMonth,
    this.isArrear = false,
    this.isSurcharge = false,
  });

  @override
  List<Object?> get props => [
    id,
    feeType,
    netAmount,
    amountDeposited,
    balance,
    academicYear,
    targetMonth,
  ];
}

class BankInfo extends Equatable {
  final String bankName;
  final String accountTitle;
  final String accountNumber;
  final String? iban;
  final String? branchCode;

  const BankInfo({
    required this.bankName,
    required this.accountTitle,
    required this.accountNumber,
    this.iban,
    this.branchCode,
  });

  @override
  List<Object?> get props => [bankName, accountTitle, accountNumber];
}

class Voucher extends Equatable {
  final int id;
  final String status;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? validityDate;
  final double totalPayableBeforeDue;
  final double totalPayableAfterDue;
  final double lateFeeDeposited;
  final String? pdfUrl;
  final String? academicYear;
  final int? month;
  final bool lateFeeCharge;
  final List<VoucherHead> heads;
  final BankInfo? bankInfo;
  final String? campusName;
  final String? className;

  const Voucher({
    required this.id,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    this.validityDate,
    required this.totalPayableBeforeDue,
    required this.totalPayableAfterDue,
    required this.lateFeeDeposited,
    this.pdfUrl,
    this.academicYear,
    this.month,
    required this.lateFeeCharge,
    required this.heads,
    this.bankInfo,
    this.campusName,
    this.className,
  });

  double get totalPaid => heads.fold(0.0, (s, h) => s + h.amountDeposited) + lateFeeDeposited;

  double get remainingLateSurcharge {
    if (!lateFeeCharge) return 0.0;
    final totalSurcharge = (totalPayableAfterDue - totalPayableBeforeDue).clamp(
      0.0,
      double.infinity,
    );
    return (totalSurcharge - lateFeeDeposited).clamp(0.0, double.infinity);
  }

  double get totalBalance {
    final headBalance = heads.fold(0.0, (s, h) => s + h.balance);
    return headBalance + (isOverdue ? remainingLateSurcharge : 0.0);
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'PAID';

  @override
  List<Object?> get props => [id, status, issueDate, dueDate];
}
