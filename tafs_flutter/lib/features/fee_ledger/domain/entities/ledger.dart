import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/student.dart';

class Ledger extends Equatable {
  final StudentProfile student;
  final List<LedgerGroup> outstanding;
  final List<LedgerGroup> paid;
  final LedgerSummary summary;

  const Ledger({
    required this.student,
    required this.outstanding,
    required this.paid,
    required this.summary,
  });

  @override
  List<Object?> get props => [student, outstanding, paid, summary];
}

class StudentProfile extends Equatable {
  final int cc;
  final String fullName;
  final String? grNumber;
  final String? campus;
  final String? className;
  final String? section;
  final String? house;
  final String? photographUrl;
  final DateTime? dob;
  final String? gender;
  final List<GuardianInfo> guardians;

  const StudentProfile({
    required this.cc,
    required this.fullName,
    this.grNumber,
    this.campus,
    this.className,
    this.section,
    this.house,
    this.photographUrl,
    this.dob,
    this.gender,
    required this.guardians,
  });

  @override
  List<Object?> get props => [
    cc, fullName, grNumber, campus, className, section, house, photographUrl, dob, gender, guardians
  ];
}

class GuardianInfo extends Equatable {
  final String name;
  final String relationship;
  final String? phone;

  const GuardianInfo({
    required this.name,
    required this.relationship,
    this.phone,
  });

  @override
  List<Object?> get props => [name, relationship, phone];
}

class LedgerGroup extends Equatable {
  final int targetMonth;
  final String academicYear;
  final String monthLabel;
  final List<LedgerHead> heads;
  final double groupPayable;

  const LedgerGroup({
    required this.targetMonth,
    required this.academicYear,
    required this.monthLabel,
    required this.heads,
    required this.groupPayable,
  });

  @override
  List<Object?> get props => [targetMonth, academicYear, monthLabel, heads, groupPayable];
}

class LedgerHead extends Equatable {
  final int id;
  final String description;
  final double amount;
  final double amountPaid;
  final double payable;
  final String status;
  final DateTime? feeDate;
  final bool isIssued;

  const LedgerHead({
    required this.id,
    required this.description,
    required this.amount,
    required this.amountPaid,
    required this.payable,
    required this.status,
    this.feeDate,
    required this.isIssued,
  });

  @override
  List<Object?> get props => [id, description, amount, amountPaid, payable, status, feeDate, isIssued];
}

class LedgerSummary extends Equatable {
  final double totalOutstanding;
  final double totalPaidThisYear;

  const LedgerSummary({
    required this.totalOutstanding,
    required this.totalPaidThisYear,
  });

  @override
  List<Object?> get props => [totalOutstanding, totalPaidThisYear];
}
