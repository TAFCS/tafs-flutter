import 'package:equatable/equatable.dart';
import 'student.dart';

class Parent extends Equatable {
  final int id;
  final String username;
  final String householdName;
  final List<Student> students;
  final List<FamilyGuardian> guardians;
  final String accessToken;
  final String refreshToken;
  final String? photographUrl;
  final String? homePhone;

  const Parent({
    required this.id,
    required this.username,
    required this.householdName,
    required this.students,
    required this.guardians,
    required this.accessToken,
    required this.refreshToken,
    this.photographUrl,
    this.homePhone,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        householdName,
        students,
        guardians,
        accessToken,
        refreshToken,
        photographUrl,
        homePhone,
      ];
}

class FamilyGuardian extends Equatable {
  final int id;
  final String name;
  final String relationship;
  final String? phone;
  final String? photographUrl;

  final String? email;
  final String? occupation;
  final String? organization;
  final String? education;
  final String? cnic;
  final String? whatsapp;
  final String? address;
  final String? houseApptName;
  final String? areaBlock;
  final String? city;
  final String? province;
  final String? country;
  final String? postalCode;
  final String? jobPosition;
  final bool isEmergencyContact;
  final List<String> pendingFields;

  const FamilyGuardian({
    required this.id,
    required this.name,
    required this.relationship,
    this.phone,
    this.photographUrl,
    this.email,
    this.occupation,
    this.organization,
    this.education,
    this.cnic,
    this.whatsapp,
    this.address,
    this.houseApptName,
    this.areaBlock,
    this.city,
    this.province,
    this.country,
    this.postalCode,
    this.jobPosition,
    this.isEmergencyContact = false,
    this.pendingFields = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        relationship,
        phone,
        photographUrl,
        email,
        occupation,
        organization,
        education,
        cnic,
        whatsapp,
        address,
        houseApptName,
        areaBlock,
        city,
        province,
        country,
        postalCode,
        jobPosition,
        isEmergencyContact,
        pendingFields,
      ];
}
