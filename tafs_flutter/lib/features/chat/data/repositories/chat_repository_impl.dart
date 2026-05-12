import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_dto.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
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
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await dio.post('/chat/media', data: formData);
    return response.data['url'] as String;
  }

  @override
  void connect() async {
    final cached = await localDataSource.getCachedParent();
    if (cached == null) return;

    final socketUrl = baseUrl.replaceAll('/api/v1', '');
    
    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': cached.accessToken})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) async {
      print('Connected to Chat Socket');
      
      // Register FCM Token
      try {
        // Request permissions for iOS
        if (Platform.isIOS) {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        }

        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          _socket!.emit('registerFcmToken', {
            'familyId': cached.id,
            'token': fcmToken,
            'deviceType': Platform.isAndroid ? 'ANDROID' : 'IOS',
          });
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
    _socket?.disconnect();
    _socket = null;
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

    _socket?.emit('markAsRead', {
      'familyId': cached.id,
      'role': 'GUARDIAN',
    });
  }

  @override
  Stream<ChatMessage> get onMessageReceived => _messageController.stream;

  @override
  Stream<void> get onMessagesRead => _readController.stream;

  @override
  Stream<String> get onMessageDeleted => _deleteController.stream;
}
