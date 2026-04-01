import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
          create: (context) => InjectionContainer.authBloc,
        ),
        BlocProvider<FeeLedgerBloc>(
          create: (context) => InjectionContainer.feeLedgerBloc,
        ),
      ],
      child: MaterialApp(
        title: 'TAFS Parent Portal',
        theme: AppTheme.lightTheme,
        home: const LoginPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
