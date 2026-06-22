import '../../auth/domain/entities/staff_user.dart';

bool canViewStaffNoticeBoard(StaffUser user) => user.role == 'SUPER_ADMIN';
