import 'package:equatable/equatable.dart';

class EmployeeProfile extends Equatable {
  final int id;
  final String? employeeCode;
  final String? fullName;
  final String? jobTitle;
  final String? staffCategory;
  final String? joinDate;
  final String? personalPhone;
  final String? personalEmail;
  final String? photoUrl;
  final bool isPermanentEmployee;
  final String? campusName;
  final String? departmentName;
  final String? designationName;
  final String? username;
  final String? accountRole;

  const EmployeeProfile({
    required this.id,
    this.employeeCode,
    this.fullName,
    this.jobTitle,
    this.staffCategory,
    this.joinDate,
    this.personalPhone,
    this.personalEmail,
    this.photoUrl,
    this.isPermanentEmployee = false,
    this.campusName,
    this.departmentName,
    this.designationName,
    this.username,
    this.accountRole,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    final campus = json['campuses'] as Map<String, dynamic>?;
    final department = json['departments'] as Map<String, dynamic>?;
    final designation = json['designations'] as Map<String, dynamic>?;
    final user = json['users'] as Map<String, dynamic>?;

    String? dateOnly(dynamic value) {
      if (value == null) return null;
      final raw = value as String;
      return raw.contains('T') ? raw.split('T').first : raw;
    }

    return EmployeeProfile(
      id: json['id'] as int,
      employeeCode: json['employee_code'] as String?,
      fullName: json['full_name'] as String?,
      jobTitle: json['job_title'] as String?,
      staffCategory: json['staff_category'] as String?,
      joinDate: dateOnly(json['join_date']),
      personalPhone: json['personal_phone'] as String?,
      personalEmail: json['personal_email'] as String?,
      photoUrl: json['photo_url'] as String?,
      isPermanentEmployee: json['is_permanent_employee'] as bool? ?? false,
      campusName: campus?['campus_name'] as String?,
      departmentName: department?['name'] as String?,
      designationName: designation?['title'] as String?,
      username: user?['username'] as String?,
      accountRole: user?['role'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeCode,
        fullName,
        jobTitle,
        staffCategory,
        joinDate,
        personalPhone,
        personalEmail,
        photoUrl,
        isPermanentEmployee,
        campusName,
        departmentName,
        designationName,
        username,
        accountRole,
      ];
}
