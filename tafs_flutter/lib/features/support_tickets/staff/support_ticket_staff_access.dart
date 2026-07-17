import '../../auth/domain/entities/staff_user.dart';

const supportTicketsViewPermission = 'communication.support_tickets.view';

const _responderRoles = {
  'GENERAL_RESPONDENT',
  'PRINCIPAL',
  'FINANCE_CLERK',
  'CAMPUS_ADMIN',
  'SUPER_ADMIN',
};

enum StaffQueueTab { myQueue, financeQueue, oversight, closed }

bool canViewSupportTickets(StaffUser user) {
  if (user.role == 'SUPER_ADMIN') return true;
  if (user.permissions.contains(supportTicketsViewPermission)) return true;
  return _responderRoles.contains(user.role);
}

StaffQueueTab defaultQueueTabForRole(String role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return StaffQueueTab.oversight;
    case 'CAMPUS_ADMIN':
      return StaffQueueTab.closed;
    default:
      return StaffQueueTab.myQueue;
  }
}

bool showFinanceTab(String role) =>
    role == 'FINANCE_CLERK' || role == 'SUPER_ADMIN';

bool showOversightTab(String role) => role == 'SUPER_ADMIN';

String queueTabLabel(StaffQueueTab tab) {
  switch (tab) {
    case StaffQueueTab.myQueue:
      return 'My Queue';
    case StaffQueueTab.financeQueue:
      return 'Finance';
    case StaffQueueTab.oversight:
      return 'All Open';
    case StaffQueueTab.closed:
      return 'Closed';
  }
}

String categoryLabel(String category) {
  final upper = category.toUpperCase();
  if (upper == 'FINANCIAL') return 'Financial';
  if (upper == 'GENERAL') return 'General';
  return category;
}

/// List/thread title: student name when set, otherwise FAMILY OF {household}.
String ticketRequesterLabel({
  String? studentName,
  String? householdName,
  int? familyId,
}) {
  final student = studentName?.trim();
  if (student != null && student.isNotEmpty) return student;

  final household = householdName?.trim();
  if (household != null && household.isNotEmpty) {
    final name = household.replaceFirst(RegExp(r'^family\s+of\s+', caseSensitive: false), '').trim();
    if (name.isNotEmpty) return 'FAMILY OF ${name.toUpperCase()}';
  }

  if (familyId != null) return 'Family #$familyId';
  return 'Family';
}

String statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'OPEN':
      return 'Open';
    case 'ASSIGNED':
      return 'Assigned';
    case 'CLOSED':
      return 'Closed';
    case 'PENDING':
      return 'Pending';
    case 'APPROVED':
      return 'Approved';
    case 'REJECTED':
      return 'Rejected';
    default:
      return status;
  }
}
