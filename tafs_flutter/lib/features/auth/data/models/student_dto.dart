import '../../domain/entities/student.dart';

class StudentDto extends Student {
  const StudentDto({
    required super.cc,
    required super.fullName,
    super.grNumber,
    super.photographUrl,
    super.campus,
    super.campusCode,
    super.className,
    super.classCode,
    super.section,
    super.academicYear,
  });

  factory StudentDto.fromJson(Map<String, dynamic> json) {
    return StudentDto(
      cc: (json['cc'] as int?) ?? 0,
      fullName: json['fullName'] as String? ?? '',
      grNumber: json['grNumber'] as String?,
      photographUrl: json['photographUrl'] as String?,
      campus: json['campus'] as String?,
      campusCode: json['campusCode'] as String?,
      className: json['className'] as String?,
      classCode: json['classCode'] as String?,
      section: json['section'] as String?,
      academicYear: json['academicYear'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cc': cc,
      'fullName': fullName,
      'grNumber': grNumber,
      'photographUrl': photographUrl,
      'campus': campus,
      'campusCode': campusCode,
      'className': className,
      'classCode': classCode,
      'section': section,
      'academicYear': academicYear,
    };
  }
}
