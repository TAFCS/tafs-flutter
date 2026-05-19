import 'dart:convert';

class ChatOutboxEntry {
  final String clientMessageId;
  final String messageType;
  final String content;
  final String? localFilePath;
  final Map<String, dynamic>? mediaMetadata;
  final String? replyToId;
  final DateTime createdAt;

  const ChatOutboxEntry({
    required this.clientMessageId,
    required this.messageType,
    required this.content,
    this.localFilePath,
    this.mediaMetadata,
    this.replyToId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'clientMessageId': clientMessageId,
        'messageType': messageType,
        'content': content,
        if (localFilePath != null) 'localFilePath': localFilePath,
        if (mediaMetadata != null) 'mediaMetadata': mediaMetadata,
        if (replyToId != null) 'replyToId': replyToId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatOutboxEntry.fromJson(Map<String, dynamic> json) {
    return ChatOutboxEntry(
      clientMessageId: json['clientMessageId'] as String,
      messageType: json['messageType'] as String,
      content: json['content'] as String,
      localFilePath: json['localFilePath'] as String?,
      mediaMetadata: json['mediaMetadata'] as Map<String, dynamic>?,
      replyToId: json['replyToId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static String encodeList(List<ChatOutboxEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<ChatOutboxEntry> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ChatOutboxEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
