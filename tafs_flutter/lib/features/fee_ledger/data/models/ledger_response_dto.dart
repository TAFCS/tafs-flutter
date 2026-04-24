import '../../domain/entities/ledger.dart';

class LedgerResponseDto extends Ledger {
  const LedgerResponseDto({
    required super.student,
    required super.outstanding,
    required super.paid,
    required super.summary,
  });

  factory LedgerResponseDto.fromJson(Map<String, dynamic> json) {
    return LedgerResponseDto(
      student: StudentProfileDto.fromJson(json['student']),
      outstanding: (json['outstanding'] as List)
          .map((e) => LedgerGroupDto.fromJson(e))
          .toList(),
      paid: (json['paid'] as List)
          .map((e) => LedgerGroupDto.fromJson(e))
          .toList(),
      summary: LedgerSummaryDto.fromJson(json['summary']),
    );
  }
}

class StudentProfileDto extends StudentProfile {
  const StudentProfileDto({
    required super.cc,
    required super.fullName,
    super.grNumber,
    super.campus,
    super.className,
    super.section,
    super.house,
    super.photographUrl,
    super.dob,
    super.gender,
    required super.guardians,
  });

  factory StudentProfileDto.fromJson(Map<String, dynamic> json) {
    return StudentProfileDto(
      cc: json['cc'] as int,
      fullName: json['full_name'] as String,
      grNumber: json['gr_number'] as String?,
      campus: json['campus'] as String?,
      className: json['class'] as String?,
      section: json['section'] as String?,
      house: json['house'] as String?,
      photographUrl: json['photograph_url'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      gender: json['gender'] as String?,
      guardians: (json['guardians'] as List)
          .map((e) => GuardianInfoDto.fromJson(e))
          .toList(),
    );
  }
}

class GuardianInfoDto extends GuardianInfo {
  const GuardianInfoDto({
    required super.name,
    required super.relationship,
    super.phone,
  });

  factory GuardianInfoDto.fromJson(Map<String, dynamic> json) {
    return GuardianInfoDto(
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class LedgerGroupDto extends LedgerGroup {
  const LedgerGroupDto({
    required super.targetMonth,
    required super.academicYear,
    required super.monthLabel,
    required super.heads,
    required super.groupPayable,
  });

  factory LedgerGroupDto.fromJson(Map<String, dynamic> json) {
    return LedgerGroupDto(
      targetMonth: json['target_month'] as int,
      academicYear: json['academic_year'] as String,
      monthLabel: json['monthLabel'] as String,
      heads: (json['heads'] as List)
          .map((e) => LedgerHeadDto.fromJson(e))
          .toList(),
      groupPayable: (json['group_payable'] as num).toDouble(),
    );
  }
}

class LedgerHeadDto extends LedgerHead {
  const LedgerHeadDto({
    required super.id,
    required super.description,
    required super.amount,
    required super.amountPaid,
    required super.payable,
    required super.status,
    super.feeDate,
    required super.isIssued,
  });

  factory LedgerHeadDto.fromJson(Map<String, dynamic> json) {
    return LedgerHeadDto(
      id: json['id'] as int,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      payable: (json['payable'] as num).toDouble(),
      status: json['status'] as String,
      feeDate: json['fee_date'] != null ? DateTime.parse(json['fee_date']) : null,
      isIssued: json['is_issued'] as bool,
    );
  }
}

class LedgerSummaryDto extends LedgerSummary {
  const LedgerSummaryDto({
    required super.totalOutstanding,
    required super.totalPaidThisYear,
  });

  factory LedgerSummaryDto.fromJson(Map<String, dynamic> json) {
    return LedgerSummaryDto(
      totalOutstanding: (json['total_outstanding'] as num).toDouble(),
      totalPaidThisYear: (json['total_paid_this_year'] as num).toDouble(),
    );
  }
}
