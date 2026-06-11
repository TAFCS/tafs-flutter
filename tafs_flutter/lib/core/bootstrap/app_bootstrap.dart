import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../firebase_options.dart';
import '../services/notification_service.dart';

/// Critical startup work before [InjectionContainer.init] (env + hydrated storage).
class AppBootstrap {
  static const Duration _envTimeout = Duration(seconds: 5);
  static const Duration _storageTimeout = Duration(seconds: 8);
  static const Duration _firebaseTimeout = Duration(seconds: 12);

  static Completer<void>? _firebaseReadyCompleter;
  static bool _firebaseReady = false;

  /// Completes when [initFirebaseAndNotifications] finishes (success or failure).
  static Future<void> waitForFirebase() async {
    if (_firebaseReady) return;
    _firebaseReadyCompleter ??= Completer<void>();
    return _firebaseReadyCompleter!.future;
  }

  static void _markFirebaseReady() {
    _firebaseReady = true;
    final completer = _firebaseReadyCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// Loads `.env` (optional) and HydratedBloc storage. Throws on storage failure.
  static Future<void> prepareCore() async {
    await _loadEnv();
    await _initHydratedStorage();
  }

  /// Firebase + local notifications — safe to run after first frame.
  static Future<void> initFirebaseAndNotifications() async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_firebaseTimeout);

      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      final notificationService = NotificationService();
      await notificationService.initialize().timeout(_firebaseTimeout);
      notificationService.setupInteractions();
    } catch (e, st) {
      debugPrint('Firebase/notifications init failed (non-fatal): $e\n$st');
    } finally {
      _markFirebaseReady();
    }
  }

  static Future<void> _loadEnv() async {
    try {
      await dotenv.load(fileName: '.env').timeout(_envTimeout);
    } catch (e) {
      debugPrint('Could not load .env (using defaults): $e');
    }
  }

  static Future<void> _initHydratedStorage() async {
    if (kIsWeb) {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory.web,
      ).timeout(_storageTimeout);
      return;
    }

    // Same path as pre-refactor main.dart (temp dir).
    final storageDir = await getTemporaryDirectory();
    final storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(storageDir.path),
    ).timeout(_storageTimeout);
    HydratedBloc.storage = storage;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling background message: ${message.messageId}');
}
