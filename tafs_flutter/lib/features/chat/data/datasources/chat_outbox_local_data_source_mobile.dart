import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/chat_outbox_entry.dart';
import 'chat_outbox_local_data_source.dart';

// ignore: non_constant_identifier_names
ChatOutboxStorage createOutboxDataSource() => _MobileOutboxStorage();

class _MobileOutboxStorage implements ChatOutboxStorage {
  Future<File> _fileForFamily(int familyId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/chat_outbox_$familyId.json');
  }

  @override
  Future<List<ChatOutboxEntry>> load(int familyId) async {
    final file = await _fileForFamily(familyId);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      if (raw.isEmpty) return [];
      return ChatOutboxEntry.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(int familyId, List<ChatOutboxEntry> entries) async {
    final file = await _fileForFamily(familyId);
    if (entries.isEmpty) {
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      return;
    }
    await file.writeAsString(ChatOutboxEntry.encodeList(entries));
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
