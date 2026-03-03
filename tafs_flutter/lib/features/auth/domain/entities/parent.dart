import 'package:equatable/equatable.dart';
import 'student.dart';

class Parent extends Equatable {
  final int id;
  final String username;
  final String householdName;
  final List<Student> students;
  final String accessToken;
  final String refreshToken;

  const Parent({
    required this.id,
    required this.username,
    required this.householdName,
    required this.students,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [id, username, householdName, students, accessToken, refreshToken];
}
