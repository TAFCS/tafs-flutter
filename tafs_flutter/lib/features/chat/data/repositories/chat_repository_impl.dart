import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_dto.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

class ChatRepositoryImpl extends ChatRepository with WidgetsBindingObserver {
  final Dio dio;
  final AuthLocalDataSource localDataSource;
  final String baseUrl;
  
  io.Socket? _socket;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _readController = StreamController<void>.broadcast();
  final _deleteController = StreamController<String>.broadcast();

  ChatRepositoryImpl({
    required this.dio,
    required this.localDataSource,
    required this.baseUrl,
  });

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
  Future<String> uploadMedia(File file) async {
    print('Chat: Uploading media: ${file.path}');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    try {
      final response = await dio.post('/chat/media', data: formData);
      print('Chat: Upload successful: ${response.data['url']}');
      return response.data['url'] as String;
    } catch (e) {
      print('Chat: Upload failed: $e');
      if (e is DioException) {
        print('Chat: Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  @override
  void connect() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;

    final socketUrl = baseUrl.replaceAll('/api/v1', '');
    
    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .setAuth({'token': cached.accessToken})
      .enableAutoConnect()
      .enableReconnection() // Ensure reconnection is explicitly enabled
      .setReconnectionDelay(1000)
      .setReconnectionAttempts(99999999) // Infinite reconnection attempts
      .setReconnectionDelayMax(5000)
      .setRandomizationFactor(0.5)
      .build());

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _socket!.onConnect((_) async {
      print('Connected to Chat Socket');
      
      // Register FCM Token
      try {
        // Request permissions
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print('FCM: Registering token for family ${cached.id}: ${fcmToken.substring(0, 10)}...');
          _socket!.emit('registerFcmToken', {
            'familyId': cached.id,
            'token': fcmToken,
            'deviceType': Platform.isAndroid ? 'ANDROID' : 'IOS',
          });
        } else {
          print('FCM: Token is null');
        }
      } catch (e) {
        if (e.toString().contains('apns-token-not-set')) {
          print('FCM: APNS token not set (expected on iOS Simulator)');
        } else {
          print('Error getting FCM token: $e');
        }
      }
    });

    _socket!.on('receiveMessage', (data) {
      final messageJson = data['message'];
      final message = ChatMessageDto.fromJson(messageJson);
      _messageController.add(message);
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
    if (state == AppLifecycleState.resumed) {
      if (_socket != null && !_socket!.connected) {
        print('Chat: App resumed, enforcing socket connection...');
        _socket!.connect();
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await dio.get('/chat/students');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching students for tagging: $e');
      return [];
    }
  }

  @override
  void sendMessage({
    required ChatMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;

    _socket?.emit('sendMessage', {
      'familyId': cached.id,
      'senderType': 'GUARDIAN',
      'messageType': type.name.toUpperCase(),
      'content': content,
      'mediaMetadata': metadata,
    });
  }

  @override
  void markAsRead() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;

    // Use REST for more reliability than socket during connection handshake
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
}
