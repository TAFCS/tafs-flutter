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
      id: _asInt(json['id'])!,
      familyId: _asInt(json['family_id'])!,
      studentCc: _asInt(json['student_cc'])!,
      voucherId: _asInt(json['voucher_id'])!,
      studentName: (json['students'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Student',
      alertType: json['alert_type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['read_at'] != null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Socket / FCM payloads omit nested `students`; merge immediately into the feed.
  static VoucherAlert? fromRealtimePayload(
    Map<String, dynamic> data, {
    required int familyId,
    String studentName = 'Student',
  }) {
    final id = _asInt(data['id']);
    final voucherId = _asInt(data['voucher_id']);
    final studentCc = _asInt(data['student_cc']);
    final alertType = data['alert_type'] as String?;
    final title = data['title'] as String?;
    final body = data['body'] as String?;
    if (id == null ||
        voucherId == null ||
        studentCc == null ||
        alertType == null ||
        title == null ||
        body == null) {
      return null;
    }

    final rawCreated = data['created_at'];
    final DateTime createdAt;
    if (rawCreated is String) {
      createdAt = DateTime.parse(rawCreated);
    } else if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else {
      createdAt = DateTime.now();
    }

    return VoucherAlertDto(
      id: id,
      familyId: familyId,
      studentCc: studentCc,
      voucherId: voucherId,
      studentName: studentName,
      alertType: alertType,
      title: title,
      body: body,
      isRead: false,
      createdAt: createdAt,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
