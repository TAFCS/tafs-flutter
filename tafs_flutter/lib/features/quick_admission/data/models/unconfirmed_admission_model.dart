import '../../domain/entities/unconfirmed_admission.dart';

class UnconfirmedAdmissionModel extends UnconfirmedAdmission {
  const UnconfirmedAdmissionModel({
    required super.id,
    required super.fullName,
    required super.dateOfBirth,
    required super.gender,
    super.address,
    super.campusId,
    super.photographUrl,
    required super.depositAmount,
    super.guardianName,
    super.guardianRelation,
    super.guardianCnic,
    required super.createdAt,
  });

  factory UnconfirmedAdmissionModel.fromJson(Map<String, dynamic> json) {
    return UnconfirmedAdmissionModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String,
      address: json['address'] as String?,
      campusId: json['campus_id'] as int?,
      photographUrl: json['photograph_url'] as String?,
      depositAmount: double.parse(json['deposit_amount'].toString()),
      guardianName: json['guardian_name'] as String?,
      guardianRelation: json['guardian_relation'] as String?,
      guardianCnic: json['guardian_cnic'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'address': address,
      'campus_id': campusId,
      'photograph_url': photographUrl,
      'deposit_amount': depositAmount,
      'guardian_name': guardianName,
      'guardian_relation': guardianRelation,
      'guardian_cnic': guardianCnic,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
