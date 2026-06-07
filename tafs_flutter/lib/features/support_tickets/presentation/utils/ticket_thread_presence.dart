/// Tracks whether the parent is viewing a specific ticket thread (for in-app notifications).
class TicketThreadPresence {
  static String? activeTicketId;

  static bool isViewing(String ticketId) => activeTicketId == ticketId;
}
