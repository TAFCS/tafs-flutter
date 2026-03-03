import '../../domain/entities/parent.dart';
import 'student_dto.dart';

class ParentDto extends Parent {
  const ParentDto({
    required super.id,
    required super.username,
    required super.householdName,
    required super.students,
    required super.accessToken,
    required super.refreshToken,
  });

  factory ParentDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final family = data['family'] as Map<String, dynamic>? ?? data;
    final studentsList = data['students'] as List<dynamic>? ?? [];

    return ParentDto(
      id: family['id'] as int,
      username: family['username'] as String,
      householdName: family['householdName'] as String? ?? '',
      students: studentsList.map((e) => StudentDto.fromJson(e as Map<String, dynamic>)).toList(),
      accessToken: data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'family': {
          'id': id,
          'username': username,
          'householdName': householdName,
        },
        'students': students.map((e) => (e as StudentDto).toJson()).toList(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      }
    };
  }
}
