import 'package:equatable/equatable.dart';

class UnconfirmedAdmission extends Equatable {
  final int id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String? address;
  final int? campusId;
  final String? photographUrl;
  final double depositAmount;
  final String? guardianName;
  final String? guardianRelation;
  final String? guardianCnic;
  final DateTime createdAt;

  const UnconfirmedAdmission({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.address,
    this.campusId,
    this.photographUrl,
    required this.depositAmount,
    this.guardianName,
    this.guardianRelation,
    this.guardianCnic,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        fullName,
        dateOfBirth,
        gender,
        address,
        campusId,
        photographUrl,
        depositAmount,
        guardianName,
        guardianRelation,
        guardianCnic,
        createdAt,
      ];
}
