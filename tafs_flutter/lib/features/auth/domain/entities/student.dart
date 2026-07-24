import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final int cc;
  final String fullName;
  final String? grNumber;
  final String? photographUrl;
  final String? campus;
  final String? campusCode;
  final String? className;
  final String? classCode;
  final String? section;
  final String? academicYear;
  final int? campusId;
  final int? classId;
  final int? sectionId;
  final String? enrollmentStatus;
  final String? graduatedFromClass;
  final DateTime? graduatedAt;

  const Student({
    required this.cc,
    required this.fullName,
    this.grNumber,
    this.photographUrl,
    this.campus,
    this.campusCode,
    this.className,
    this.classCode,
    this.section,
    this.academicYear,
    this.campusId,
    this.classId,
    this.sectionId,
    this.enrollmentStatus,
    this.graduatedFromClass,
    this.graduatedAt,
  });

  bool get isGraduated => enrollmentStatus == 'GRADUATED';

  @override
  List<Object?> get props => [
        cc,
        fullName,
        grNumber,
        photographUrl,
        campus,
        className,
        section,
        academicYear,
        campusId,
        classId,
        sectionId,
        enrollmentStatus,
        graduatedFromClass,
        graduatedAt,
      ];
}
