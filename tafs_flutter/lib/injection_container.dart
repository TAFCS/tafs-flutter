import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/parent_login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class InjectionContainer {
  static late final AuthBloc authBloc;

  static void init() {
    // Core Data Sources
    final dio = Dio();
    const secureStorage = FlutterSecureStorage();

    final remoteDataSource = AuthRemoteDataSourceImpl(dio);
    final localDataSource = AuthLocalDataSourceImpl(secureStorage);

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
  }
}
