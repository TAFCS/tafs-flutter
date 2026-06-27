import 'package:equatable/equatable.dart';

class StaffUser extends Equatable {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final int? campusId;
  final String? campusName;
  final List<int> allowedClassIds;
  final List<String> permissions;
  final bool hasEmployeeProfile;
  final String accessToken;
  final String refreshToken;

  const StaffUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.campusId,
    this.campusName,
    this.allowedClassIds = const [],
    this.permissions = const [],
    this.hasEmployeeProfile = false,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        role,
        campusId,
        campusName,
        allowedClassIds,
        permissions,
        hasEmployeeProfile,
        accessToken,
        refreshToken,
      ];
}
