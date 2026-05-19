import '../entities/chat_message.dart';

/// Merges server history with local state, resolving pending optimistic rows.
List<ChatMessage> mergeChatMessagesWithServer({
  required List<ChatMessage> current,
  required List<ChatMessage> serverRecent,
}) {
  final serverByTempId = <String, ChatMessage>{};
  for (final m in serverRecent) {
    final tempId = m.mediaMetadata?['tempId'] as String?;
    if (tempId != null) {
      serverByTempId[tempId] = m;
    }
  }

  final mergedById = <String, ChatMessage>{};
  final pendingUnresolved = <ChatMessage>[];

  for (final m in current) {
    final isPending = m.status == MessageStatus.sending ||
        m.status == MessageStatus.queued ||
        (m.status == MessageStatus.error && m.id.startsWith('temp-'));

    if (isPending) {
      final matched = serverByTempId[m.id];
      if (matched != null) {
        mergedById[matched.id] = matched;
      } else {
        pendingUnresolved.add(m);
      }
    } else {
      mergedById[m.id] = m;
    }
  }

  for (final m in serverRecent) {
    mergedById[m.id] = m;
  }

  final combined = [...pendingUnresolved, ...mergedById.values];
  combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return combined;
}
