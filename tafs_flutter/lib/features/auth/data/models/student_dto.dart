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
    super.campusId,
    super.classId,
    super.sectionId,
    super.enrollmentStatus,
    super.graduatedFromClass,
    super.graduatedAt,
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
      campusId: json['campusId'] as int?,
      classId: json['classId'] as int?,
      sectionId: json['sectionId'] as int?,
      enrollmentStatus: json['enrollmentStatus'] as String?,
      graduatedFromClass: json['graduatedFromClass'] as String?,
      graduatedAt: json['graduatedAt'] != null
          ? DateTime.tryParse(json['graduatedAt'] as String)
          : null,
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
      'campusId': campusId,
      'classId': classId,
      'sectionId': sectionId,
      'enrollmentStatus': enrollmentStatus,
      'graduatedFromClass': graduatedFromClass,
      'graduatedAt': graduatedAt?.toIso8601String(),
    };
  }
}
