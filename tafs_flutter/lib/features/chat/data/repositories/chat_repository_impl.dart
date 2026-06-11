import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/config/app_config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/services/fcm_registration_service.dart';
import 'package:flutter/widgets.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_outbox_entry.dart';
import '../../domain/entities/chat_student.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_outbox_local_data_source.dart';
import '../models/chat_message_dto.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

const announcementConversationId = '00000000-0000-0000-0000-000000000000';

class ChatRepositoryImpl extends ChatRepository with WidgetsBindingObserver {
  final Dio dio;
  final AuthLocalDataSource localDataSource;
  final ChatOutboxLocalDataSource outboxDataSource;
  final String baseUrl;

  io.Socket? _socket;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _readController = StreamController<String>.broadcast();
  final _deleteController = StreamController<String>.broadcast();
  final _connectController = StreamController<void>.broadcast();
  final _disconnectController = StreamController<void>.broadcast();
  final _sessionExpiredController = StreamController<void>.broadcast();
  final _ticketMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _ticketQueueChangedController = StreamController<void>.broadcast();
  final _replyPendingApprovalController = StreamController<void>.broadcast();
  final _announcementController = StreamController<ChatMessage>.broadcast();
  bool _isRefreshingToken = false;
  bool _isDrainingOutbox = false;

  /// Fires when the refresh token is also expired — the app should redirect to login.
  @override
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
  Stream<Map<String, dynamic>> get onTicketMessagePayload =>
      _ticketMessageController.stream;

  @override
  Stream<void> get onTicketQueueChanged =>
      _ticketQueueChangedController.stream;

  @override
  Stream<void> get onReplyPendingApproval =>
      _replyPendingApprovalController.stream;

  void _emitTicketQueueChanged() {
    if (!_ticketQueueChangedController.isClosed) {
      _ticketQueueChangedController.add(null);
    }
  }

  @override
  void enterTicket(String ticketId) {
    _socket?.emit('enterTicket', {'ticketId': ticketId});
  }

  @override
  void leaveTicket(String ticketId) {
    _socket?.emit('leaveTicket', {'ticketId': ticketId});
  }

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
    final token = await localDataSource.getActiveAccessToken();
    if (token == null) return;

    final socketUrl = baseUrl.replaceAll('/api/v1', '');

    if (_socket != null) {
      _socket!.io.options?['auth'] = {'token': token};
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .setAuth({'token': token})
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
          final isStaff = await localDataSource.hasStaffSession();
          final refreshBaseUrl = AppConfig.apiBaseUrl;
          String? newAccessToken;

          if (isStaff) {
            final cached = await localDataSource.getCachedStaff();
            if (cached == null || cached.refreshToken.isEmpty) {
              _socket?.io.options?['reconnectionAttempts'] = 0;
              _socket?.disconnect();
              _sessionExpiredController.add(null);
              return;
            }
            final response = await Dio().post(
              '$refreshBaseUrl/auth/staff/mobile/refresh',
              data: {'refreshToken': cached.refreshToken},
              options: Options(
                headers: {'Content-Type': 'application/json'},
                validateStatus: (s) => s != null && s < 500,
              ),
            );
            if (response.statusCode == 200 && response.data != null) {
              final body = response.data['data'] ?? response.data;
              newAccessToken = body['accessToken'] as String?;
              final newRefresh = body['refreshToken'] as String?;
              if (newAccessToken != null) {
                await localDataSource.cacheStaff(cached.copyWith(
                  accessToken: newAccessToken,
                  refreshToken: newRefresh ?? cached.refreshToken,
                ));
              }
            }
          } else {
            final cached = await localDataSource.getCachedParent();
            if (cached == null || cached.refreshToken.isEmpty) {
              _socket?.io.options?['reconnectionAttempts'] = 0;
              _socket?.disconnect();
              _sessionExpiredController.add(null);
              return;
            }
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
              newAccessToken = body['accessToken'] as String?;
              final newRefreshToken = body['refreshToken'] as String?;
              if (newAccessToken != null) {
                final updated = cached.copyWith(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken ?? cached.refreshToken,
                );
                await localDataSource.cacheParent(updated);
              }
            }
          }

          if (newAccessToken != null && _socket != null) {
            _socket!.io.options?['auth'] = {'token': newAccessToken};
            _socket!.io.options?['reconnectionAttempts'] = 99999;
            _socket!.connect();
          } else {
            _socket?.disconnect();
            _sessionExpiredController.add(null);
          }
        } catch (e) {
          print('[ChatRepo] Token refresh failed: $e');
          // Restore auto-reconnect so the next attempt can retry the refresh.
          // Leaving it at 0 permanently bricks the socket for the session.
          _socket?.io.options?['reconnectionAttempts'] = 99999;
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
        final latest = await localDataSource.getActiveAccessToken();
        if (latest != null && _socket != null) {
          _socket!.io.options?['auth'] = {'token': latest};
        }
      }
    });

    _socket!.on('reconnect_attempt', (_) async {
      final latest = await localDataSource.getActiveAccessToken();
      if (latest != null && _socket != null) {
        _socket!.io.options?['auth'] = {'token': latest};
      }
    });

    // Backend signals token is expired — the auto-reconnect that follows will
    // trigger connect_error where the actual token refresh happens.
    _socket!.on('tokenExpired', (_) {
      print('[ChatRepo] Server signalled token expired; awaiting auto-reconnect');
    });

    _socket!.onConnect((_) async {
      _connectController.add(null);

      // Backup socket registration; REST registration is primary (see FcmRegistrationService).
      if (!kIsWeb) {
        try {
          final fcmToken = await FcmRegistrationService.instance.getToken();
          final parent = await localDataSource.getCachedParent();
          if (parent != null && fcmToken != null) {
            _socket!.emit('registerFcmToken', {
              'familyId': parent.id,
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
        if (_isAnnouncementMessage(message)) {
          _announcementController.add(message);
        }
      } catch (e) {
        print('Error parsing receiveMessage: $e');
      }
    });

    _socket!.on('messagesRead', (data) {
      final by = (data is Map ? data['by'] : null) as String? ?? 'ADMIN';
      _readController.add(by);
    });

    _socket!.on('messageDeleted', (data) {
      final messageId = data['messageId'] as String;
      _deleteController.add(messageId);
    });

    _socket!.on('ticketMessageReceived', (data) {
      try {
        if (data is Map) {
          _ticketMessageController.add(Map<String, dynamic>.from(data));
        }
        _emitTicketQueueChanged();
      } catch (e) {
        print('Error parsing ticketMessageReceived: $e');
      }
    });

    for (final event in [
      'ticketCreated',
      'ticketClaimed',
      'ticketTransferred',
      'ticketForwarded',
      'ticketClosed',
      'replyReviewed',
    ]) {
      _socket!.on(event, (_) => _emitTicketQueueChanged());
    }

    _socket!.on('replyPendingApproval', (_) {
      _emitTicketQueueChanged();
      if (!_replyPendingApprovalController.isClosed) {
        _replyPendingApprovalController.add(null);
      }
    });

    _socket!.onDisconnect((reason) {
      print('[ChatRepo] Disconnected from socket. Reason: $reason');
      _disconnectController.add(null);
      // The socket.io client's built-in reconnection logic will handle
      // reconnecting. We do NOT manually call connect() here to avoid
      // creating duplicate connections.
    });

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
    if (state == AppLifecycleState.resumed) {
      if (_socket == null) return;
      // Always force a clean reconnect on resume. After backgrounding, the OS
      // can kill the TCP connection while socket.io still reports connected==true
      // (zombie). Trusting that flag causes outbox flushes to time out after 15s
      // and inbound messages to be silently dropped.
      // onConnect fires once the fresh handshake completes and drains the outbox.
      _socket!.disconnect();
      _socket!.connect();
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
  Future<List<ChatStudent>> getStudents() async {
    try {
      final response = await dio.get('/chat/students');
      return (response.data as List<dynamic>)
          .map((s) => ChatStudent(
                cc: s['cc'] as int,
                fullName: s['full_name'] as String? ?? '',
                photographUrl: s['photograph_url'] as String?,
              ))
          .toList();
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
  Future<void> acknowledgeMessage(String messageId) async {
    await dio.post('/chat/messages/$messageId/acknowledge');
  }

  @override
  Stream<ChatMessage> get onMessageReceived => _messageController.stream;

  @override
  Stream<String> get onMessagesRead => _readController.stream;

  @override
  Stream<String> get onMessageDeleted => _deleteController.stream;

  @override
  Stream<void> get onConnect => _connectController.stream;

  @override
  Stream<void> get onDisconnect => _disconnectController.stream;

  bool _isAnnouncementMessage(ChatMessage message) {
    return message.isAnnouncement ||
        message.conversationId == announcementConversationId;
  }

  @override
  Future<List<ChatMessage>> getAdminAnnouncementHistory({
    int take = 50,
    int skip = 0,
  }) async {
    final response = await dio.get(
      '/chat/history/admin/0',
      queryParameters: {'take': take, 'skip': skip},
    );
    final data = response.data;
    final List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else {
      items = const [];
    }
    return items
        .map((json) => ChatMessageDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  void sendAnnouncement({
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
    String? targetGrade,
    String? targetSection,
  }) {
    _socket?.emit('sendAnnouncement', {
      'messageType': messageType.toUpperCase(),
      'content': content,
      if (mediaMetadata != null) 'mediaMetadata': mediaMetadata,
      if (targetGrade != null) 'targetGrade': targetGrade,
      if (targetSection != null) 'targetSection': targetSection,
    });
  }

  @override
  Stream<ChatMessage> get onAnnouncementReceived =>
      _announcementController.stream;
}
