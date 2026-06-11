import '../../auth/domain/entities/staff_user.dart';

const announcementsChatViewPermission = 'communication.view_chats';

bool canViewAnnouncementsChat(StaffUser user) {
  if (user.role == 'SUPER_ADMIN') return true;
  return user.permissions.contains(announcementsChatViewPermission);
}

bool canSendAnnouncements(StaffUser user) => canViewAnnouncementsChat(user);
