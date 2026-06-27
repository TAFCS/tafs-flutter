import '../auth/domain/entities/staff_user.dart';

/// Self-service attendance and payroll are limited to the EMPLOYEES role.
bool canViewEmployeePortal(StaffUser user) => user.role == 'EMPLOYEES';
