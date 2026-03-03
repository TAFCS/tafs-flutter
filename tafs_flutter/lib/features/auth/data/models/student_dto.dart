import '../../domain/entities/student.dart';

class StudentDto extends Student {
  const StudentDto({
    required super.id,
    required super.fullName,
    required super.section,
    super.profilePictureUrl,
  });

  factory StudentDto.fromJson(Map<String, dynamic> json) {
    return StudentDto(
      id: json['id'],
      fullName: json['fullName'],
      section: json['section'],
      profilePictureUrl: json['profilePictureUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'section': section,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
