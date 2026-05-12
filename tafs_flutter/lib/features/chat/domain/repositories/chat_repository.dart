import '../entities/chat_message.dart';
import 'dart:io';

abstract class ChatRepository {
  Future<List<ChatMessage>> getChatHistory({int take = 50, int skip = 0});
  Future<String> uploadMedia(File file);
  void connect();
  void disconnect();
  void sendMessage({
    required ChatMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
  });
  void markAsRead();
  void enterChat();
  void leaveChat();
  Stream<ChatMessage> get onMessageReceived;
  Stream<void> get onMessagesRead;
  Stream<String> get onMessageDeleted;
}
