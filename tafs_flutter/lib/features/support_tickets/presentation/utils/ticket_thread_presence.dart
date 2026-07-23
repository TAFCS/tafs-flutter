/// Tracks whether a parent or staff user is viewing a specific ticket thread
/// (for in-app notifications and unread-badge suppression).
class TicketThreadPresence {
  static String? activeTicketId;

  static bool isViewing(String ticketId) => activeTicketId == ticketId;
}
