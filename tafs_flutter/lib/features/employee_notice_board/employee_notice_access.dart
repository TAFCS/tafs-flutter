import '../auth/domain/entities/staff_user.dart';

/// Every authenticated staff user sees the employee notice board.
/// The backend filters what they see based on their role and campus.
bool canViewEmployeeNoticeBoard(StaffUser user) => true;
