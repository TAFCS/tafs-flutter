import '../../domain/entities/chat_outbox_entry.dart';
import 'chat_outbox_local_data_source_mobile.dart'
    if (dart.library.html) 'chat_outbox_local_data_source_web.dart';

/// Abstract interface for the offline message outbox.
/// Implementations: _MobileOutboxStorage (file+path_provider) and
/// _WebOutboxStorage (shared_preferences/IndexedDB).
abstract class ChatOutboxStorage {
  Future<List<ChatOutboxEntry>> load(int familyId);
  Future<void> save(int familyId, List<ChatOutboxEntry> entries);
  Future<void> enqueue(int familyId, ChatOutboxEntry entry);
  Future<void> remove(int familyId, String clientMessageId);
}

/// Public class used everywhere in the app.
/// Conditionally resolves to _MobileOutboxStorage or _WebOutboxStorage.
class ChatOutboxLocalDataSource implements ChatOutboxStorage {
  final ChatOutboxStorage _impl = createOutboxDataSource();

  @override
  Future<List<ChatOutboxEntry>> load(int familyId) => _impl.load(familyId);
  @override
  Future<void> save(int familyId, List<ChatOutboxEntry> entries) =>
      _impl.save(familyId, entries);
  @override
  Future<void> enqueue(int familyId, ChatOutboxEntry entry) =>
      _impl.enqueue(familyId, entry);
  @override
  Future<void> remove(int familyId, String clientMessageId) =>
      _impl.remove(familyId, clientMessageId);
}
