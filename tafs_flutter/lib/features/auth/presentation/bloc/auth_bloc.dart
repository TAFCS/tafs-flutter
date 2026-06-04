import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../data/models/parent_dto.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/parent_login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  final ParentLoginUseCase loginUseCase;
  final AuthRepository repository;

  AuthBloc({
    required this.loginUseCase,
    required this.repository,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthDeleteAccountRequested>(_onAuthDeleteAccountRequested);
    on<AuthVerifyCnicRequested>(_onVerifyCnicRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthSignupResetRequested>(_onSignupResetRequested);
    on<AuthSignupExitToLoginRequested>(_onSignupExitToLoginRequested);
    on<AuthRefreshRequested>(_onAuthRefreshRequested);
    on<AuthTokenRefreshed>(_onAuthTokenRefreshed);
  }

  // ─── HydratedBloc serialization ────────────────────────────────────────────
  // Only persist AuthAuthenticated. All transient / signup states return null,
  // meaning hydrated_bloc falls back to the initial state (AuthInitial).

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    if (state is AuthAuthenticated) {
      return (state.parent as ParentDto).toJson();
    }
    return null;
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      final parent = ParentDto.fromJson(json);
      if (parent.accessToken.isEmpty || parent.refreshToken.isEmpty) {
        return null;
      }
      return AuthAuthenticated(parent);
    } catch (_) {
      // Any deserialization error → start fresh (show login)
      return null;
    }
  }

  // ─── Event handlers ────────────────────────────────────────────────────────

  /// Still kept so other parts of the code can trigger a manual check.
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

  Future<void> _onAuthRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.refreshProfile();
    result.fold(
      (failure) => null, // Keep existing state on failure
      (parent) => emit(AuthAuthenticated(parent)),
    );
  }

  /// Called by [TokenInterceptor] when it silently refreshes the access token
  /// on a 401 response. Emitting [AuthAuthenticated] with the updated parent
  /// keeps the in-memory BLoC state and the HydratedBloc JSON cache in sync
  /// with [FlutterSecureStorage] — preventing the dual-storage desync that
  /// caused stale-token loops after app restart.
  Future<void> _onAuthTokenRefreshed(
    AuthTokenRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(event.parent));
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      event.username,
      event.password,
      fcmToken: event.fcmToken,
      deviceType: event.deviceType,
    );
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
    await clear(); // Wipe hydrated_bloc disk cache so restart shows login
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.deleteAccount();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) async {
        await clear(); // Wipe hydrated_bloc disk cache so restart shows login
        emit(AuthUnauthenticated());
      },
    );
  }

  // ─── Signup handlers ───────────────────────────────────────────────────────

  Future<void> _onVerifyCnicRequested(
    AuthVerifyCnicRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignupCnicVerifying());
    final result = await repository.verifyCnic(event.cnic);
    result.fold(
      (failure) => emit(SignupCnicInvalid(failure.message)),
      (result) {
        if (result.exists) {
          emit(SignupCnicValid(
            cnic: event.cnic,
            guardianName: result.guardianName ?? 'Guardian',
          ));
        } else {
          emit(SignupCnicInvalid(result.message ?? 'CNIC not found'));
        }
      },
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignupRegistering());
    final result = await repository.registerParent(
      event.cnic,
      event.email,
      event.password,
      fcmToken: event.fcmToken,
      deviceType: event.deviceType,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (parent) => emit(SignupSuccess(parent)),
    );
  }

  Future<void> _onSignupResetRequested(
    AuthSignupResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignupInitial());
  }

  Future<void> _onSignupExitToLoginRequested(
    AuthSignupExitToLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthUnauthenticated());
  }
}
