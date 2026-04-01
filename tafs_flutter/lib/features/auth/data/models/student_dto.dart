import '../../domain/entities/student.dart';

class StudentDto extends Student {
  const StudentDto({
    required super.cc,
    required super.fullName,
    super.section,
    super.profilePictureUrl,
  });

  factory StudentDto.fromJson(Map<String, dynamic> json) {
    return StudentDto(
      cc: (json['cc'] as int?) ?? 0,
      fullName: json['fullName'] as String? ?? '',
      section: json['section'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cc': cc,
      'fullName': fullName,
      'section': section,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
