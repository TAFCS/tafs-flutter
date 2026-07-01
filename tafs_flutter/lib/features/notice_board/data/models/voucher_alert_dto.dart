import '../../domain/entities/voucher_alert.dart';

class VoucherAlertDto extends VoucherAlert {
  const VoucherAlertDto({
    required super.id,
    required super.familyId,
    required super.studentCc,
    required super.voucherId,
    required super.studentName,
    required super.alertType,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
  });

  factory VoucherAlertDto.fromJson(Map<String, dynamic> json) {
    return VoucherAlertDto(
      id: json['id'] as int,
      familyId: json['family_id'] as int,
      studentCc: json['student_cc'] as int,
      voucherId: json['voucher_id'] as int,
      studentName: (json['students'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Student',
      alertType: json['alert_type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['read_at'] != null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
