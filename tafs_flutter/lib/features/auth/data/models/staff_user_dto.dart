import '../../domain/entities/staff_user.dart';

class StaffUserDto extends StaffUser {
  const StaffUserDto({
    required super.id,
    required super.username,
    required super.fullName,
    required super.role,
    super.campusId,
    super.campusName,
    super.allowedClassIds,
    super.permissions,
    required super.accessToken,
    required super.refreshToken,
  });

  factory StaffUserDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final user = data['user'] as Map<String, dynamic>? ?? data;
    final allowedRaw = user['allowedClassIds'] ?? user['allowed_class_ids'];
    final permissionsRaw = user['permissions'];

    return StaffUserDto(
      id: user['id']?.toString() ?? '',
      username: user['username'] as String? ?? '',
      fullName: user['fullName'] as String? ?? user['full_name'] as String? ?? '',
      role: user['role'] as String? ?? '',
      campusId: user['campusId'] as int? ?? user['campus_id'] as int?,
      campusName: user['campusName'] as String? ?? user['campus_name'] as String?,
      allowedClassIds: allowedRaw is List
          ? allowedRaw.map((e) => (e as num).toInt()).toList()
          : const [],
      permissions: permissionsRaw is List
          ? permissionsRaw.map((e) => e.toString()).toList()
          : const [],
      accessToken: data['accessToken'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionType': 'staff',
        'data': {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'user': {
            'id': id,
            'username': username,
            'fullName': fullName,
            'role': role,
            'campusId': campusId,
            'campusName': campusName,
            'allowedClassIds': allowedClassIds,
            'permissions': permissions,
          },
        },
      };

  StaffUserDto copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return StaffUserDto(
      id: id,
      username: username,
      fullName: fullName,
      role: role,
      campusId: campusId,
      campusName: campusName,
      allowedClassIds: allowedClassIds,
      permissions: permissions,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
