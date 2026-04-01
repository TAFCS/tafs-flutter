import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/token_interceptor.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/parent_login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

// Fee Ledger
import 'features/fee_ledger/data/datasources/fee_ledger_remote_data_source.dart';
import 'features/fee_ledger/data/repositories/fee_ledger_repository_impl.dart';
import 'features/fee_ledger/domain/usecases/get_student_vouchers_usecase.dart';
import 'features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';

class InjectionContainer {
  static late final AuthBloc authBloc;
  static late final FeeLedgerBloc feeLedgerBloc;

  static void init() {
    // Core
    final dio = Dio();
    const secureStorage = FlutterSecureStorage();

    final localDataSource = AuthLocalDataSourceImpl(secureStorage);
    final remoteDataSource = AuthRemoteDataSourceImpl(dio);

    // Repository
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    final feeLedgerRemoteDataSource = FeeLedgerRemoteDataSourceImpl(dio);
    final feeLedgerRepository = FeeLedgerRepositoryImpl(
      remoteDataSource: feeLedgerRemoteDataSource,
    );

    // Use cases
    final parentLoginUseCase = ParentLoginUseCase(authRepository);
    final getStudentVouchersUseCase = GetStudentVouchersUseCase(feeLedgerRepository);

    // BLoCs
    authBloc = AuthBloc(
      loginUseCase: parentLoginUseCase,
      repository: authRepository,
    );

    feeLedgerBloc = FeeLedgerBloc(
      getStudentVouchers: getStudentVouchersUseCase,
    );

    // ── Dio interceptors ───────────────────────────────────────────────────
    // Must be registered after authBloc so the TokenInterceptor callback
    // can reference it.

    // 1. Attach access token to every outgoing request automatically
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final cached = await localDataSource.getCachedParent();
          if (cached != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer ${cached.accessToken}';
          }
          handler.next(options);
        },
      ),
    );

    // 2. Silently refresh on 401; trigger logout if refresh also fails
    dio.interceptors.add(
      TokenInterceptor(
        localDataSource: localDataSource,
        onLogout: () => authBloc.add(AuthLogoutRequested()),
      ),
    );
  }
}
