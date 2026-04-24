import '../../domain/entities/voucher.dart';

class VoucherHeadDto extends VoucherHead {
  const VoucherHeadDto({
    required super.id,
    required super.feeType,
    required super.netAmount,
    required super.amountDeposited,
    required super.balance,
    super.discountLabel,
    required super.discountAmount,
    super.academicYear,
    super.targetMonth,
    super.isArrear,
    super.isSurcharge,
  });

  factory VoucherHeadDto.fromJson(Map<String, dynamic> json) {
    final fee = json['student_fees'] as Map<String, dynamic>? ?? {};
    final feeType = fee['fee_types'] as Map<String, dynamic>? ?? {};

    return VoucherHeadDto(
      id: (json['id'] as int?) ?? 0,
      feeType: (json['description'] as String?) ??
          (feeType['description'] as String?) ??
          'Fee',
      netAmount: _toDouble(json['netAmount'] ?? json['net_amount']),
      amountDeposited: _toDouble(
        json['amountDeposited'] ?? json['amount_deposited'],
      ),
      balance: _toDouble(json['balance']),
      discountLabel: (json['discountLabel'] as String?) ??
          (json['discount_label'] as String?),
      discountAmount: _toDouble(
        json['discountAmount'] ?? json['discount_amount'],
      ),
      academicYear: (json['academic_year'] as String?) ??
          (fee['academic_year'] as String?),
      targetMonth: (json['target_month'] as int?) ?? (fee['target_month'] as int?),
      isArrear: (json['isArrear'] as bool?) ?? (json['is_arrear'] as bool?) ?? false,
      isSurcharge: (json['isSurcharge'] as bool?) ?? (json['is_surcharge'] as bool?) ?? false,
    );
  }
}

class BankInfoDto extends BankInfo {
  const BankInfoDto({
    required super.bankName,
    required super.accountTitle,
    required super.accountNumber,
    super.iban,
    super.branchCode,
  });

  factory BankInfoDto.fromJson(Map<String, dynamic> json) {
    return BankInfoDto(
      bankName: json['bank_name'] as String? ?? '',
      accountTitle: json['account_title'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      iban: json['iban'] as String?,
      branchCode: json['branch_code'] as String?,
    );
  }
}

class VoucherDto extends Voucher {
  const VoucherDto({
    required super.id,
    required super.status,
    required super.issueDate,
    required super.dueDate,
    super.validityDate,
    required super.totalPayableBeforeDue,
    required super.totalPayableAfterDue,
    required super.lateFeeDeposited,
    super.pdfUrl,
    super.academicYear,
    super.month,
    required super.lateFeeCharge,
    required super.heads,
    super.bankInfo,
    super.campusName,
    super.className,
  });

  factory VoucherDto.fromJson(Map<String, dynamic> json) {
    final heads = (json['voucher_heads'] as List<dynamic>? ?? [])
        .map((h) => VoucherHeadDto.fromJson(h as Map<String, dynamic>))
        .toList();

    final bank = json['bank_accounts'] != null
        ? BankInfoDto.fromJson(json['bank_accounts'] as Map<String, dynamic>)
        : null;

    return VoucherDto(
      id: (json['id'] as int?) ?? 0,
      status: json['status'] as String? ?? 'UNPAID',
      issueDate:
          DateTime.tryParse(json['issue_date'] as String? ?? '') ??
          DateTime.now(),
      dueDate:
          DateTime.tryParse(json['due_date'] as String? ?? '') ??
          DateTime.now(),
      validityDate: json['validity_date'] != null
          ? DateTime.tryParse(json['validity_date'] as String)
          : null,
      totalPayableBeforeDue: _toDouble(json['total_payable_before_due']),
      totalPayableAfterDue: _toDouble(json['total_payable_after_due']),
      lateFeeDeposited: _toDouble(json['late_fee_deposited']),
      pdfUrl: json['pdf_url'] as String?,
      academicYear: json['academic_year'] as String?,
      month: json['month'] as int?,
      lateFeeCharge: json['late_fee_charge'] as bool? ?? false,
      heads: heads,
      bankInfo: bank,
      campusName:
          (json['campuses'] as Map<String, dynamic>?)?['campus_name']
              as String?,
      className:
          (json['classes'] as Map<String, dynamic>?)?['description'] as String?,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
