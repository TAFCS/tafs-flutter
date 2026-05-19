import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/chat_outbox_entry.dart';

class ChatOutboxLocalDataSource {
  Future<File> _fileForFamily(int familyId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/chat_outbox_$familyId.json');
  }

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

  Future<void> save(int familyId, List<ChatOutboxEntry> entries) async {
    final file = await _fileForFamily(familyId);
    if (entries.isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.writeAsString(ChatOutboxEntry.encodeList(entries));
  }

  Future<void> enqueue(int familyId, ChatOutboxEntry entry) async {
    final entries = await load(familyId);
    entries.removeWhere((e) => e.clientMessageId == entry.clientMessageId);
    entries.add(entry);
    await save(familyId, entries);
  }

  Future<void> remove(int familyId, String clientMessageId) async {
    final entries = await load(familyId);
    entries.removeWhere((e) => e.clientMessageId == clientMessageId);
    await save(familyId, entries);
  }
}
