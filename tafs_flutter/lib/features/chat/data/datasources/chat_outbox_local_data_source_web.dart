import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_outbox_entry.dart';
import 'chat_outbox_local_data_source.dart';

// ignore: non_constant_identifier_names
ChatOutboxStorage createOutboxDataSource() => _WebOutboxStorage();

class _WebOutboxStorage implements ChatOutboxStorage {
  static const _keyPrefix = 'chat_outbox_';

  String _key(int familyId) => '$_keyPrefix$familyId';

  @override
  Future<List<ChatOutboxEntry>> load(int familyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(familyId));
      if (raw == null || raw.isEmpty) return [];
      return ChatOutboxEntry.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(int familyId, List<ChatOutboxEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await prefs.remove(_key(familyId));
      return;
    }
    await prefs.setString(_key(familyId), ChatOutboxEntry.encodeList(entries));
  }

  @override
  Future<void> enqueue(int familyId, ChatOutboxEntry entry) async {
    final entries = await load(familyId);
    entries.removeWhere((e) => e.clientMessageId == entry.clientMessageId);
    entries.add(entry);
    await save(familyId, entries);
  }

  @override
  Future<void> remove(int familyId, String clientMessageId) async {
    final entries = await load(familyId);
    entries.removeWhere((e) => e.clientMessageId == clientMessageId);
    await save(familyId, entries);
  }
}
