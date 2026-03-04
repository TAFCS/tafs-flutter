import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/token_interceptor.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/parent_login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

class InjectionContainer {
  static late final AuthBloc authBloc;

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

    // Use cases
    final parentLoginUseCase = ParentLoginUseCase(authRepository);

    // BLoCs
    authBloc = AuthBloc(
      loginUseCase: parentLoginUseCase,
      repository: authRepository,
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
