import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'dart:async';
import '../../../../core/error/api_error_mapper.dart';
import '../../../../core/services/fcm_registration_service.dart';
import '../../../../injection_container.dart';
import '../../data/models/parent_dto.dart';
import '../../data/models/staff_user_dto.dart';
import '../../domain/entities/parent.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/parent_login_usecase.dart';
import '../../domain/usecases/staff_login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  final ParentLoginUseCase loginUseCase;
  final StaffLoginUseCase staffLoginUseCase;
  final AuthRepository repository;

  AuthBloc({
    required this.loginUseCase,
    required this.staffLoginUseCase,
    required this.repository,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthStaffLoginRequested>(_onAuthStaffLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthDeleteAccountRequested>(_onAuthDeleteAccountRequested);
    on<AuthAccountDeletionRequestedAcknowledged>(
      _onAccountDeletionRequestedAcknowledged,
    );
    on<AuthVerifyCnicRequested>(_onVerifyCnicRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthSignupResetRequested>(_onSignupResetRequested);
    on<AuthSignupExitToLoginRequested>(_onSignupExitToLoginRequested);
    on<AuthRefreshRequested>(_onAuthRefreshRequested);
    on<AuthProfileRefreshFailureAcknowledged>(_onProfileRefreshFailureAcknowledged);
    on<AuthTokenRefreshed>(_onAuthTokenRefreshed);
    on<AuthStaffRefreshRequested>(_onAuthStaffRefreshRequested);
    on<AuthStaffTokenRefreshed>(_onAuthStaffTokenRefreshed);
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    if (state is AuthAuthenticated) {
      return {
        'sessionType': 'parent',
        ...(state.parent as ParentDto).toJson(),
      };
    }
    if (state is AuthAuthenticatedStaff) {
      return (state.staff as StaffUserDto).toJson();
    }
    return null;
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['sessionType'] == 'staff') {
        final staff = StaffUserDto.fromJson(json);
        if (staff.accessToken.isEmpty || staff.refreshToken.isEmpty) return null;
        return AuthAuthenticatedStaff(staff);
      }
      final parent = ParentDto.fromJson(json);
      if (parent.accessToken.isEmpty || parent.refreshToken.isEmpty) return null;
      return AuthAuthenticated(parent);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final staffResult = await repository.getCachedStaff();
    final staff = staffResult.fold((_) => null, (s) => s);
    if (staff != null) {
      emit(AuthAuthenticatedStaff(staff));
      final refreshed = await repository.refreshStaffSession();
      refreshed.fold((_) {}, (updated) => emit(AuthAuthenticatedStaff(updated)));
      return;
    }

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
    final Parent? currentParent = switch (state) {
      AuthAuthenticated(:final parent) => parent,
      AuthProfileRefreshFailed(:final parent) => parent,
      _ => null,
    };

    if (currentParent == null) return;

    final result = await repository.refreshProfile();
    result.fold(
      (failure) => emit(AuthProfileRefreshFailed(
        parent: currentParent,
        message: ApiErrorMapper.userMessage(failure),
      )),
      (parent) => emit(AuthAuthenticated(parent)),
    );
  }

  void _onProfileRefreshFailureAcknowledged(
    AuthProfileRefreshFailureAcknowledged event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(event.parent));
  }

  Future<void> _onAuthTokenRefreshed(
    AuthTokenRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(event.parent));
  }

  Future<void> _onAuthStaffRefreshRequested(
    AuthStaffRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticatedStaff) return;

    final result = await repository.refreshStaffSession();
    result.fold((_) {}, (staff) => emit(AuthAuthenticatedStaff(staff)));
  }

  Future<void> _onAuthStaffTokenRefreshed(
    AuthStaffTokenRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticatedStaff(event.staff));
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
      (failure) => emit(AuthError(ApiErrorMapper.userMessage(failure))),
      (parent) => emit(AuthAuthenticated(parent)),
    );
  }

  Future<void> _onAuthStaffLoginRequested(
    AuthStaffLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await staffLoginUseCase(event.username, event.password);
    result.fold(
      (failure) => emit(AuthError(ApiErrorMapper.userMessage(failure))),
      (staff) {
        if (InjectionContainer.isInitialized) {
          unawaited(
            FcmRegistrationService.instance.registerWithBackend(
              InjectionContainer.dio,
              staff: true,
            ),
          );
        }
        emit(AuthAuthenticatedStaff(staff));
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.logout();
    await clear();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    final Parent? currentParent = switch (state) {
      AuthAuthenticated(:final parent) => parent,
      AuthProfileRefreshFailed(:final parent) => parent,
      _ => null,
    };
    if (currentParent == null) return;

    final result = await repository.requestAccountDeletion();
    result.fold(
      (failure) => emit(AuthProfileRefreshFailed(
        parent: currentParent,
        message: ApiErrorMapper.userMessage(failure),
      )),
      (_) => emit(AuthAccountDeletionRequested(currentParent)),
    );
  }

  void _onAccountDeletionRequestedAcknowledged(
    AuthAccountDeletionRequestedAcknowledged event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(event.parent));
  }

  Future<void> _onVerifyCnicRequested(
    AuthVerifyCnicRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignupCnicVerifying());
    final result = await repository.verifyCnic(event.cnic);
    result.fold(
      (failure) => emit(SignupCnicInvalid(ApiErrorMapper.userMessage(failure))),
      (result) {
        if (result.exists) {
          emit(SignupCnicValid(
            cnic: event.cnic,
            guardianName: result.guardianName ?? 'Guardian',
          ));
        } else {
          emit(SignupCnicInvalid(
            ApiErrorMapper.sanitize(
              result.message,
              fallback: 'CNIC not found in system.',
            ),
          ));
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
      (failure) => emit(SignupRegisterFailed(
        message: ApiErrorMapper.userMessage(failure),
        cnic: event.cnic,
        guardianName: event.guardianName,
      )),
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
