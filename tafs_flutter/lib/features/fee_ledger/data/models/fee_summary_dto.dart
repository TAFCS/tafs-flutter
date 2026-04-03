import '../../domain/entities/fee_summary.dart';

class FeeSummaryDto extends FeeSummary {
  const FeeSummaryDto({
    super.academicYear,
    required super.totalCharged,
    required super.totalPaid,
    required super.outstandingBalance,
    required super.hasOverdue,
    required super.overdueCount,
  });

  factory FeeSummaryDto.fromJson(Map<String, dynamic> json) {
    return FeeSummaryDto(
      academicYear: json['academicYear'] as String?,
      totalCharged: _toDouble(json['totalCharged']),
      totalPaid: _toDouble(json['totalPaid']),
      outstandingBalance: _toDouble(json['outstandingBalance']),
      hasOverdue: json['hasOverdue'] as bool? ?? false,
      overdueCount: (json['overdueCount'] as int?) ?? 0,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
