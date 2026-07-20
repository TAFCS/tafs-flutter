import '../../domain/entities/parent.dart';
import '../../domain/entities/student.dart';
import 'student_dto.dart';

class ParentDto extends Parent {
  const ParentDto({
    required super.id,
    required super.username,
    required super.householdName,
    required super.students,
    required super.guardians,
    required super.accessToken,
    required super.refreshToken,
    super.photographUrl,
    super.homePhone,
  });

  factory ParentDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final family = data['family'] as Map<String, dynamic>? ?? data;
    final studentsList = data['students'] as List<dynamic>? ?? [];
    final guardiansList = family['guardians'] as List<dynamic>? ?? [];

    return ParentDto(
      id: (family['id'] as int?) ?? 0,
      username: family['email'] as String? ?? '',
      householdName: family['householdName'] as String? ?? '',
      photographUrl: (family['photographUrl'] as String?) ??
          (family['photograph_url'] as String?),
      homePhone: (family['homePhone'] as String?) ??
          (family['home_phone'] as String?),
      students: studentsList
          .map((e) => StudentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      guardians: guardiansList
          .map((e) => FamilyGuardianDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      accessToken: data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'family': {
          'id': id,
          'email': username,
          'householdName': householdName,
          'photographUrl': photographUrl,
          'homePhone': homePhone,
          'guardians': guardians
              .map((e) => (e as FamilyGuardianDto).toJson())
              .toList(),
        },
        'students': students.map((e) => (e as StudentDto).toJson()).toList(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    };
  }

  ParentDto copyWith({
    int? id,
    String? username,
    String? householdName,
    List<Student>? students,
    List<FamilyGuardian>? guardians,
    String? accessToken,
    String? refreshToken,
    String? photographUrl,
    String? homePhone,
  }) {
    return ParentDto(
      id: id ?? this.id,
      username: username ?? this.username,
      householdName: householdName ?? this.householdName,
      students: students ?? this.students,
      guardians: guardians ?? this.guardians,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      photographUrl: photographUrl ?? this.photographUrl,
      homePhone: homePhone ?? this.homePhone,
    );
  }
}

class FamilyGuardianDto extends FamilyGuardian {
  const FamilyGuardianDto({
    required super.id,
    required super.name,
    required super.relationship,
    super.phone,
    super.photographUrl,
    super.email,
    super.occupation,
    super.organization,
    super.education,
    super.cnic,
    super.whatsapp,
    super.address,
    super.houseApptName,
    super.areaBlock,
    super.city,
    super.province,
    super.country,
    super.postalCode,
    super.jobPosition,
    super.isEmergencyContact,
    super.pendingFields,
  });

  factory FamilyGuardianDto.fromJson(Map<String, dynamic> json) {
    return FamilyGuardianDto(
      id: json['id'] as int,
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      phone: json['phone'] as String?,
      photographUrl: (json['photographUrl'] as String?) ??
          (json['photograph_url'] as String?) ??
          (json['photo_url'] as String?),
      email: json['email'] as String?,
      occupation: json['occupation'] as String?,
      organization: json['organization'] as String?,
      education: json['education'] as String?,
      cnic: json['cnic'] as String?,
      whatsapp: json['whatsapp'] as String?,
      address: json['address'] as String?,
      houseApptName: (json['houseApptName'] as String?) ??
          (json['house_appt_name'] as String?),
      areaBlock: (json['areaBlock'] as String?) ??
          (json['area_block'] as String?),
      city: json['city'] as String?,
      province: json['province'] as String?,
      country: json['country'] as String?,
      postalCode: (json['postalCode'] as String?) ??
          (json['postal_code'] as String?),
      jobPosition: (json['jobPosition'] as String?) ??
          (json['job_position'] as String?),
      isEmergencyContact: (json['isEmergencyContact'] as bool?) ?? false,
      pendingFields: (json['pendingFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['pending_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'photographUrl': photographUrl,
      'email': email,
      'occupation': occupation,
      'organization': organization,
      'education': education,
      'cnic': cnic,
      'whatsapp': whatsapp,
      'address': address,
      'houseApptName': houseApptName,
      'areaBlock': areaBlock,
      'city': city,
      'province': province,
      'country': country,
      'postalCode': postalCode,
      'jobPosition': jobPosition,
      'isEmergencyContact': isEmergencyContact,
      'pendingFields': pendingFields,
    };
  }
}
