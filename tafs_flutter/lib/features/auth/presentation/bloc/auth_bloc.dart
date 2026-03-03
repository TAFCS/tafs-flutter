import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/parent_login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ParentLoginUseCase loginUseCase;
  final AuthRepository repository;

  AuthBloc({
    required this.loginUseCase,
    required this.repository,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.getCachedUser();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (parent) {
        if (parent != null) {
          emit(AuthAuthenticated(parent));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.username, event.password);
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (parent) => emit(AuthAuthenticated(parent)),
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.logout();
    emit(AuthUnauthenticated());
  }
}
