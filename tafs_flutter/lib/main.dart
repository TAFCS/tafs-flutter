import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import 'features/fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import 'features/auth/presentation/bloc/selected_student_cubit.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/bloc/chat_event.dart';
import 'features/notice_board/presentation/bloc/notice_board_bloc.dart';
import 'features/notice_board/presentation/bloc/notice_board_event.dart';
import 'injection_container.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is only initialized on mobile — web has no registered Firebase app
  // and push notifications require a service worker not yet configured.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final notificationService = NotificationService();
    await notificationService.initialize();
    notificationService.setupInteractions();
  }

  await dotenv.load(fileName: '.env');

  // ── Initialize HydratedBloc storage ───────────────────────────────────────
  // On web, HydratedStorage defaults to IndexedDB — no directory needed.
  // On mobile, use the temporary directory.
  if (kIsWeb) {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory.web,
    );
  } else {
    final storageDir = await getTemporaryDirectory();
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(storageDir.path),
    );
  }

  InjectionContainer.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => InjectionContainer.authBloc,
        ),
        BlocProvider<FeeLedgerBloc>(
          create: (_) => InjectionContainer.feeLedgerBloc,
        ),
        BlocProvider<FeeSummaryBloc>(
          create: (_) => InjectionContainer.feeSummaryBloc,
        ),
        BlocProvider<SelectedStudentCubit>(
          create: (_) => InjectionContainer.selectedStudentCubit,
        ),
        BlocProvider<ChatBloc>(
          create: (_) => InjectionContainer.chatBloc..add(ChatStarted()),
        ),
        BlocProvider<NoticeBoardBloc>(
          create: (_) => InjectionContainer.noticeBoardBloc..add(const NoticeBoardLoadRequested()),
        ),
      ],
      child: MaterialApp(
        title: 'TAFS Parent Portal',
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
