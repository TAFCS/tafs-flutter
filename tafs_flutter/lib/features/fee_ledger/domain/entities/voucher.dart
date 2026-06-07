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

class VoucherArrearSurcharge extends Equatable {
  final int id;
  final int arrearMonth;
  final String arrearYear;
  final double amount;
  final double amountPaid;
  final bool waived;

  const VoucherArrearSurcharge({
    required this.id,
    required this.arrearMonth,
    required this.arrearYear,
    required this.amount,
    required this.amountPaid,
    this.waived = false,
  });

  double get balance =>
      waived ? 0.0 : (amount - amountPaid).clamp(0.0, double.infinity);

  @override
  List<Object?> get props => [id, amount, amountPaid, waived];
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
  final List<VoucherArrearSurcharge> arrearSurcharges;
  final BankInfo? bankInfo;
  final String? campusName;
  final String? className;

  /// Server-computed totals from normalizeVoucher (preferred over client math).
  final double? serverTotalBalance;
  final double? surchargeBalance;
  final double? headBalance;
  final double? serverTotalDeposited;

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
    this.arrearSurcharges = const [],
    this.bankInfo,
    this.campusName,
    this.className,
    this.serverTotalBalance,
    this.surchargeBalance,
    this.headBalance,
    this.serverTotalDeposited,
  });

  List<VoucherArrearSurcharge> get activeArrearSurcharges =>
      arrearSurcharges.where((s) => !s.waived).toList();

  double get totalPaid =>
      serverTotalDeposited ??
      (heads.fold(0.0, (s, h) => s + h.amountDeposited) +
          lateFeeDeposited +
          activeArrearSurcharges.fold(0.0, (s, a) => s + a.amountPaid));

  double get remainingLateSurcharge {
    if (!lateFeeCharge) return 0.0;
    final totalSurcharge = (totalPayableAfterDue - totalPayableBeforeDue).clamp(
      0.0,
      double.infinity,
    );
    return (totalSurcharge - lateFeeDeposited).clamp(0.0, double.infinity);
  }

  double get _clientHeadBalance =>
      headBalance ?? heads.fold(0.0, (s, h) => s + h.balance);

  double get _clientArrearSurchargeBalance =>
      surchargeBalance ??
      activeArrearSurcharges.fold(0.0, (s, a) => s + a.balance);

  double get totalBalance {
    if (serverTotalBalance != null) return serverTotalBalance!;

    return _clientHeadBalance +
        _clientArrearSurchargeBalance +
        (isOverdue ? remainingLateSurcharge : 0.0);
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'PAID';

  @override
  List<Object?> get props => [id, status, issueDate, dueDate];
}
