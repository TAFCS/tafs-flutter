import 'package:equatable/equatable.dart';

class VoucherAlert extends Equatable {
  final int id;
  final int familyId;
  final int studentCc;
  final int voucherId;
  final String studentName;
  final String alertType;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const VoucherAlert({
    required this.id,
    required this.familyId,
    required this.studentCc,
    required this.voucherId,
    required this.studentName,
    required this.alertType,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  VoucherAlert copyWith({bool? isRead}) {
    return VoucherAlert(
      id: id,
      familyId: familyId,
      studentCc: studentCc,
      voucherId: voucherId,
      studentName: studentName,
      alertType: alertType,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  bool get isOverdueAlert => alertType == 'BECAME_OVERDUE';

  bool get isExpiryAlert => alertType.startsWith('EXPIRY_REMINDER_');

  bool get isIssuedAlert => alertType == 'VOUCHER_ISSUED';

  @override
  List<Object?> get props => [id, familyId, studentCc, voucherId, alertType, isRead];
}
