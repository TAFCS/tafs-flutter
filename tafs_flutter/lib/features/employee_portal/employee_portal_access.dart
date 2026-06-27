import '../auth/domain/entities/staff_user.dart';

const attendanceSelfViewPermission = 'attendance.self.view';
const payrollSelfViewPermission = 'payroll.self.view';

bool _hasPermission(StaffUser user, String permission) =>
    user.permissions.contains(permission);

bool _isEmployeeSelfServiceRole(StaffUser user) =>
    user.role == 'EMPLOYEE' || user.role == 'EMPLOYEES';

/// HR-linked profile flag; legacy sessions may still carry EMPLOYEES until re-login.
bool _hasEmployeeProfileForSelfService(StaffUser user) =>
    user.hasEmployeeProfile || _isEmployeeSelfServiceRole(user);

/// Own attendance requires self-view permission and a linked HR employee profile.
bool canViewOwnAttendance(StaffUser user) =>
    _hasEmployeeProfileForSelfService(user) &&
    (_hasPermission(user, attendanceSelfViewPermission) ||
        _isEmployeeSelfServiceRole(user));

/// Own payroll requires self-view permission and a linked HR employee profile.
bool canViewOwnPayroll(StaffUser user) =>
    _hasEmployeeProfileForSelfService(user) &&
    (_hasPermission(user, payrollSelfViewPermission) ||
        _isEmployeeSelfServiceRole(user));

bool canViewEmployeePortal(StaffUser user) =>
    canViewOwnAttendance(user) || canViewOwnPayroll(user);
