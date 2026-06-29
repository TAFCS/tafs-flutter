import 'package:equatable/equatable.dart';

class LeaveType extends Equatable {
  final int id;
  final String code;
  final String name;
  final bool isPaid;

  const LeaveType({
    required this.id,
    required this.code,
    required this.name,
    required this.isPaid,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      isPaid: json['is_paid'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, code, name, isPaid];
}

class LeaveRequest extends Equatable {
  final int id;
  final String status;
  final String leaveTypeCode;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final String? reason;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? reviewReason;
  final String? reviewedAt;
  final String createdAt;

  const LeaveRequest({
    required this.id,
    required this.status,
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.attachmentUrl,
    this.attachmentType,
    this.reviewReason,
    this.reviewedAt,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final leaveType = json['leave_types'] as Map<String, dynamic>? ?? {};
    return LeaveRequest(
      id: json['id'] as int,
      status: json['status'] as String,
      leaveTypeCode: leaveType['code'] as String? ?? '',
      leaveTypeName: leaveType['name'] as String? ?? '',
      startDate: _dateOnly(json['start_date']),
      endDate: _dateOnly(json['end_date']),
      reason: json['reason'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      reviewReason: json['review_reason'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  static String _dateOnly(dynamic value) {
    final raw = value as String;
    return raw.contains('T') ? raw.split('T').first : raw;
  }

  @override
  List<Object?> get props => [
        id,
        status,
        leaveTypeCode,
        leaveTypeName,
        startDate,
        endDate,
        reason,
        attachmentUrl,
        attachmentType,
        reviewReason,
        reviewedAt,
        createdAt,
      ];
}

class LeaveSelfContext extends Equatable {
  final int employeeId;
  final bool isPermanentEmployee;
  final List<LeaveType> leaveTypes;

  const LeaveSelfContext({
    required this.employeeId,
    required this.isPermanentEmployee,
    required this.leaveTypes,
  });

  factory LeaveSelfContext.fromJson(Map<String, dynamic> json) {
    return LeaveSelfContext(
      employeeId: json['employeeId'] as int,
      isPermanentEmployee: json['isPermanentEmployee'] as bool? ?? false,
      leaveTypes: (json['leaveTypes'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(LeaveType.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [employeeId, isPermanentEmployee, leaveTypes];
}
