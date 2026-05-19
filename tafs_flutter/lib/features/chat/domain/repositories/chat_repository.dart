import '../entities/chat_message.dart';
import '../entities/chat_outbox_entry.dart';
import 'dart:io';

abstract class ChatRepository {
  Future<List<ChatMessage>> getChatHistory({int take = 50, int skip = 0});
  Future<String> uploadMedia(File file);
  void connect();
  void disconnect();
  bool get isConnected;
  Future<ChatMessage> sendMessage({
    required ChatMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
  });
  Future<void> enqueueOutbox(ChatOutboxEntry entry);
  Future<void> removeFromOutbox(String clientMessageId);
  Future<List<ChatOutboxEntry>> getPendingOutbox();
  Future<void> drainOutbox();
  Future<ChatMessage?> retryOutboxMessage(String clientMessageId);
  Future<List<Map<String, dynamic>>> getStudents();
  void markAsRead();
  void enterChat();
  void leaveChat();
  Stream<ChatMessage> get onMessageReceived;
  Stream<void> get onMessagesRead;
  Stream<String> get onMessageDeleted;
  Stream<void> get onConnect;
}
