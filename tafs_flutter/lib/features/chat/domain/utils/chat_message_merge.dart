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

/// Merges an older page of history (fetched for infinite-scroll pagination)
/// into the current list. Unlike a plain append, this dedupes by id (a
/// message the older-page REST call re-fetches that already arrived live in
/// the meantime must not be duplicated) and re-sorts, since [current] and
/// [olderPage] are not guaranteed to be non-overlapping or already ordered
/// relative to each other.
List<ChatMessage> mergeOlderMessagesIntoHistory({
  required List<ChatMessage> current,
  required List<ChatMessage> olderPage,
}) {
  final byId = <String, ChatMessage>{};
  for (final m in current) {
    byId[m.id] = m;
  }
  for (final m in olderPage) {
    byId.putIfAbsent(m.id, () => m);
  }
  final combined = byId.values.toList();
  combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return combined;
}
