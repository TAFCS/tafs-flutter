import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_outbox_entry.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_outbox_local_data_source.dart';
import '../models/chat_message_dto.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

class ChatRepositoryImpl extends ChatRepository with WidgetsBindingObserver {
  final Dio dio;
  final AuthLocalDataSource localDataSource;
  final ChatOutboxLocalDataSource outboxDataSource;
  final String baseUrl;

  io.Socket? _socket;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _readController = StreamController<void>.broadcast();
  final _deleteController = StreamController<String>.broadcast();
  final _connectController = StreamController<void>.broadcast();
  final _sessionExpiredController = StreamController<void>.broadcast();
  bool _isRefreshingToken = false;
  bool _isDrainingOutbox = false;

  /// Fires when the refresh token is also expired — the app should redirect to login.
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  ChatRepositoryImpl({
    required this.dio,
    required this.localDataSource,
    required this.outboxDataSource,
    required this.baseUrl,
  });

  @override
  bool get isConnected => _socket != null && _socket!.connected;

  @override
  Future<List<ChatMessage>> getChatHistory({int take = 50, int skip = 0}) async {
    final response = await dio.get(
      '/chat/history/parent',
      queryParameters: {'take': take, 'skip': skip},
    );

    final List<dynamic> data = response.data;
    return data.map<ChatMessage>((json) => ChatMessageDto.fromJson(json)).toList();
  }

  @override
  Future<String> uploadMedia(XFile file) async {
    MultipartFile multipartFile;
    if (kIsWeb) {
      // On web, dart:io File is unavailable. Read bytes directly from XFile.
      // XFile.readAsBytes() works for both regular data XFiles and blob URLs
      // (returned by the record package after voice recording).
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'upload';
      // Prefer the MIME type from XFile (set by MediaRecorder for blobs),
      // fall back to extension-based detection.
      final mime = file.mimeType ?? _mimeFromFilename(filename);
      multipartFile = MultipartFile.fromBytes(bytes, filename: filename,
          contentType: MediaType.parse(mime));
    } else {
      multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      );
    }

    final formData = FormData.fromMap({'file': multipartFile});
    final response = await dio.post('/chat/media', data: formData);
    return response.data['url'] as String;
  }

  /// Detects MIME type from a filename extension.
  String _mimeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'webm': return 'audio/webm';
      case 'opus': return 'audio/ogg; codecs=opus';
      case 'm4a':  return 'audio/mp4';
      case 'mp3':  return 'audio/mpeg';
      case 'ogg':  return 'audio/ogg';
      case 'wav':  return 'audio/wav';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'gif':  return 'image/gif';
      case 'webp': return 'image/webp';
      case 'pdf':  return 'application/pdf';
      default:     return 'application/octet-stream';
    }
  }

  @override
  void connect() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;

    final socketUrl = baseUrl.replaceAll('/api/v1', '');

    if (_socket != null) {
      _socket!.io.options?['auth'] = {'token': cached.accessToken};
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .setAuth({'token': cached.accessToken})
      .enableAutoConnect()
      .enableReconnection()
      .setReconnectionDelay(1000)
      .setReconnectionAttempts(99999999)
      .setReconnectionDelayMax(5000)
      .setRandomizationFactor(0.5)
      .build());

    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);

    _socket!.on('connect_error', (err) async {
      final errStr = err?.toString() ?? '';
      // Backend middleware sends exact strings: 'token_expired' or 'unauthorized'
      final isJwtExpired = errStr.contains('token_expired');
      final isUnauthorized = errStr.contains('unauthorized');

      if (isJwtExpired && !_isRefreshingToken) {
        _isRefreshingToken = true;
        // Pause auto-reconnect while we refresh
        _socket?.io.options?['reconnectionAttempts'] = 0;
        try {
          final cached = await localDataSource.getCachedParent();
          if (cached == null || cached.refreshToken.isEmpty) {
            _socket?.io.options?['reconnectionAttempts'] = 0;
            _socket?.disconnect();
            _sessionExpiredController.add(null);
            return;
          }

          final refreshBaseUrl =
              dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
          final response = await Dio().post(
            '$refreshBaseUrl/auth/parent/refresh',
            data: {'refreshToken': cached.refreshToken},
            options: Options(
              headers: {'Content-Type': 'application/json'},
              validateStatus: (s) => s != null && s < 500,
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            final body = response.data['data'] ?? response.data;
            final newAccessToken = body['accessToken'] as String?;
            final newRefreshToken = body['refreshToken'] as String?;

            if (newAccessToken != null) {
              final updated = cached.copyWith(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken ?? cached.refreshToken,
              );
              await localDataSource.cacheParent(updated);

              if (_socket != null) {
                _socket!.io.options?['auth'] = {'token': newAccessToken};
                _socket!.io.options?['reconnectionAttempts'] = 99999;
                _socket!.connect(); // reconnect with fresh token
              }
            } else {
              _socket?.disconnect();
              _sessionExpiredController.add(null);
            }
          } else {
            _socket?.disconnect();
            _sessionExpiredController.add(null);
          }
        } catch (e) {
          print('[ChatRepo] Token refresh failed: $e');
        } finally {
          _isRefreshingToken = false;
        }
      } else if (isUnauthorized) {
        // Not authenticated — stop reconnecting, force login
        _socket?.io.options?['reconnectionAttempts'] = 0;
        _socket?.disconnect();
        _sessionExpiredController.add(null);
      } else if (!isJwtExpired && !isUnauthorized) {
        // Network / other error — just update the token for the next attempt
        final latest = await localDataSource.getCachedParent();
        if (latest != null && _socket != null) {
          _socket!.io.options?['auth'] = {'token': latest.accessToken};
        }
      }
    });

    _socket!.on('reconnect_attempt', (_) async {
      // Token is updated in connect_error handler; just ensure latest is applied.
      final latest = await localDataSource.getCachedParent();
      if (latest != null && _socket != null) {
        _socket!.io.options?['auth'] = {'token': latest.accessToken};
      }
    });

    // Backend signals token is expired — the auto-reconnect that follows will
    // trigger connect_error where the actual token refresh happens.
    _socket!.on('tokenExpired', (_) {
      print('[ChatRepo] Server signalled token expired; awaiting auto-reconnect');
    });

    _socket!.onConnect((_) async {
      _connectController.add(null);

      // FCM push tokens are only available on Android/iOS (Firebase not init'd on web)
      if (!kIsWeb) {
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            _socket!.emit('registerFcmToken', {
              'familyId': cached.id,
              'token': fcmToken,
              'deviceType': Platform.isAndroid ? 'ANDROID' : 'IOS',
            });
          }
        } catch (e) {
          if (!e.toString().contains('apns-token-not-set')) {
            print('Error getting FCM token: $e');
          }
        }
      }

      unawaited(drainOutbox());
    });

    _socket!.on('receiveMessage', (data) {
      try {
        final messageJson = data['message'];
        final message = ChatMessageDto.fromJson(messageJson);
        _messageController.add(message);
      } catch (e) {
        print('Error parsing receiveMessage: $e');
      }
    });

    _socket!.on('messagesRead', (_) {
      _readController.add(null);
    });

    _socket!.on('messageDeleted', (data) {
      final messageId = data['messageId'] as String;
      _deleteController.add(messageId);
    });

    _socket!.onDisconnect((_) => print('Disconnected from Chat Socket'));

    _socket!.connect();
  }

  @override
  void disconnect() {
    WidgetsBinding.instance.removeObserver(this);
    _socket?.disconnect();
    _socket = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web, 'resumed' fires whenever the browser tab regains focus.
    // Calling drainOutbox on web causes path_provider crashes.
    // The socket's onConnect handler already drains the outbox reliably.
    if (kIsWeb) return;
    if (state == AppLifecycleState.resumed) {
      if (_socket != null && !_socket!.connected) {
        _socket!.connect();
      } else if (isConnected) {
        unawaited(drainOutbox());
      }
    }
  }

  ChatMessageType _parseMessageType(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return ChatMessageType.image;
      case 'VOICE':
        return ChatMessageType.voice;
      case 'DOCUMENT':
        return ChatMessageType.document;
      default:
        return ChatMessageType.text;
    }
  }

  @override
  Future<void> enqueueOutbox(ChatOutboxEntry entry) async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;
    await outboxDataSource.enqueue(cached.id, entry);
  }

  @override
  Future<void> removeFromOutbox(String clientMessageId) async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;
    await outboxDataSource.remove(cached.id, clientMessageId);
  }

  @override
  Future<List<ChatOutboxEntry>> getPendingOutbox() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return [];
    return outboxDataSource.load(cached.id);
  }

  Future<ChatMessage> _sendViaSocket({
    required ChatMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
    required int familyId,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket is disconnected');
    }

    final completer = Completer<ChatMessage>();

    _socket!.emitWithAck('sendMessage', {
      'familyId': familyId,
      'senderType': 'GUARDIAN',
      'messageType': type.name.toUpperCase(),
      'content': content,
      'mediaMetadata': metadata,
    }, ack: (response) {
      if (response != null && response is Map && response.containsKey('error')) {
        completer.completeError(Exception(response['error']));
      } else if (response != null) {
        try {
          final message = ChatMessageDto.fromJson(Map<String, dynamic>.from(response));
          completer.complete(message);
        } catch (e) {
          completer.completeError(e);
        }
      } else {
        completer.completeError(Exception('No response from server'));
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('Message send timed out'),
    );
  }

  Future<ChatMessage> _sendViaRest({
    required ChatMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await dio.post('/chat/messages', data: {
      'messageType': type.name.toUpperCase(),
      'content': content,
      'mediaMetadata': metadata,
    });
    return ChatMessageDto.fromJson(Map<String, dynamic>.from(response.data));
  }

  @override
  Future<ChatMessage> sendMessage({
    required ChatMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) {
      throw Exception('No cached session');
    }

    try {
      if (isConnected) {
        return await _sendViaSocket(
          type: type,
          content: content,
          metadata: metadata,
          familyId: cached.id,
        );
      }
    } catch (_) {
      // Fall through to REST
    }

    return _sendViaRest(type: type, content: content, metadata: metadata);
  }

  Future<ChatMessage> _flushOutboxEntry(ChatOutboxEntry entry, int familyId) async {
    var content = entry.content;
    final metadata = <String, dynamic>{
      'tempId': entry.clientMessageId,
      if (entry.mediaMetadata != null) ...entry.mediaMetadata!,
    };
    if (entry.replyToId != null) {
      metadata['replyToId'] = entry.replyToId;
    }

    // Local file upload: only supported on mobile.
    // On web there is no local filesystem; mediaMetadata['url'] should
    // already be set from the upload before the entry was queued.
    if (!kIsWeb && entry.localFilePath != null) {
      final ioFile = File(entry.localFilePath!);
      if (await ioFile.exists()) {
        // Wrap dart:io File in XFile so uploadMedia's cross-platform
        // signature is satisfied (XFile is the common abstraction).
        content = await uploadMedia(XFile(ioFile.path));
        metadata['url'] = content;
      }
    }

    final type = _parseMessageType(entry.messageType);
    ChatMessage confirmed;

    try {
      if (isConnected) {
        confirmed = await _sendViaSocket(
          type: type,
          content: content,
          metadata: metadata,
          familyId: familyId,
        );
      } else {
        throw Exception('Socket disconnected');
      }
    } catch (_) {
      confirmed = await _sendViaRest(
        type: type,
        content: content,
        metadata: metadata,
      );
    }

    await outboxDataSource.remove(familyId, entry.clientMessageId);
    _messageController.add(confirmed);
    return confirmed;
  }

  @override
  Future<void> drainOutbox() async {
    if (_isDrainingOutbox) return;
    _isDrainingOutbox = true;

    try {
      final cached = await localDataSource.getCachedParent();
      if (cached == null) return;

      final entries = await outboxDataSource.load(cached.id);
      for (final entry in List<ChatOutboxEntry>.from(entries)) {
        try {
          await _flushOutboxEntry(entry, cached.id);
        } catch (e) {
          print('Outbox flush failed for ${entry.clientMessageId}: $e');
        }
      }
    } finally {
      _isDrainingOutbox = false;
    }
  }

  @override
  Future<ChatMessage?> retryOutboxMessage(String clientMessageId) async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return null;

    final entries = await outboxDataSource.load(cached.id);
    ChatOutboxEntry? entry;
    for (final e in entries) {
      if (e.clientMessageId == clientMessageId) {
        entry = e;
        break;
      }
    }
    if (entry == null) return null;

    try {
      return await _flushOutboxEntry(entry, cached.id);
    } catch (e) {
      print('Retry failed for $clientMessageId: $e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await dio.get('/chat/students');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  @override
  void markAsRead() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;

    try {
      await dio.post('/chat/mark-read');
    } catch (e) {
      print('Error marking as read via REST: $e');
    }

    _socket?.emit('markAsRead', {
      'familyId': cached.id,
      'role': 'GUARDIAN',
    });
  }

  @override
  void enterChat() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;
    _socket?.emit('enterChat', {'familyId': cached.id});
  }

  @override
  void leaveChat() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;
    _socket?.emit('leaveChat', {'familyId': cached.id});
  }

  @override
  Stream<ChatMessage> get onMessageReceived => _messageController.stream;

  @override
  Stream<void> get onMessagesRead => _readController.stream;

  @override
  Stream<String> get onMessageDeleted => _deleteController.stream;

  @override
  Stream<void> get onConnect => _connectController.stream;
}
