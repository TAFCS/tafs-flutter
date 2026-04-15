import '../../domain/entities/fee_month_status.dart';

class FeeMonthStatusDto extends FeeMonthStatus {
  const FeeMonthStatusDto({
    required super.academicYear,
    required super.targetMonth,
    required super.monthLabel,
    required super.totalAmount,
    required super.totalPaid,
    required super.outstandingBalance,
    required super.runningOutstandingBalance,
    required super.status,
    super.feeDate,
  });

  factory FeeMonthStatusDto.fromJson(Map<String, dynamic> json) {
    final targetMonth = _toInt(json['target_month'] ?? json['targetMonth']);
    return FeeMonthStatusDto(
      academicYear: (json['academic_year'] ?? json['academicYear'] ?? '')
          .toString(),
      targetMonth: targetMonth,
      monthLabel:
          (json['month_label'] ??
                  json['monthLabel'] ??
                  _monthLabel(targetMonth))
              .toString(),
      totalAmount: _toDouble(json['month_total_amount'] ?? json['totalAmount']),
      totalPaid: _toDouble(json['month_total_paid'] ?? json['totalPaid']),
      outstandingBalance: _toDouble(
        json['month_total_outstanding'] ?? json['outstandingBalance'],
      ),
      runningOutstandingBalance: _toDouble(
        json['running_outstanding_total'] ?? json['runningOutstandingBalance'],
      ),
      status: (json['month_status'] ?? json['status'] ?? 'ISSUED').toString(),
      feeDate: _toDate(json['fee_date'] ?? json['feeDate']),
    );
  }

  static String _monthLabel(int month) {
    const labels = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return 'Unknown';
    return labels[month - 1];
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
