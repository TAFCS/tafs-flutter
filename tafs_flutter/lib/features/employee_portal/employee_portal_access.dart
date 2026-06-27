import '../auth/domain/entities/staff_user.dart';

const attendanceSelfViewPermission = 'attendance.self.view';
const payrollSelfViewPermission = 'payroll.self.view';

bool _hasPermission(StaffUser user, String permission) =>
    user.permissions.contains(permission);

/// HR-linked profile flag; EMPLOYEES logins from before this field was added
/// may have false until re-login — still allow the self-service tabs for them.
bool _hasEmployeeProfileForSelfService(StaffUser user) =>
    user.hasEmployeeProfile || user.role == 'EMPLOYEES';

/// Own attendance requires self-view permission and a linked HR employee profile.
bool canViewOwnAttendance(StaffUser user) =>
    _hasEmployeeProfileForSelfService(user) &&
    (_hasPermission(user, attendanceSelfViewPermission) ||
        user.role == 'EMPLOYEES');

/// Own payroll requires self-view permission and a linked HR employee profile.
bool canViewOwnPayroll(StaffUser user) =>
    _hasEmployeeProfileForSelfService(user) &&
    (_hasPermission(user, payrollSelfViewPermission) || user.role == 'EMPLOYEES');

bool canViewEmployeePortal(StaffUser user) =>
    canViewOwnAttendance(user) || canViewOwnPayroll(user);
