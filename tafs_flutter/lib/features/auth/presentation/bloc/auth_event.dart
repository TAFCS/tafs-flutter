import 'package:equatable/equatable.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/staff_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthRefreshRequested extends AuthEvent {}

class AuthProfileRefreshFailureAcknowledged extends AuthEvent {
  final Parent parent;

  const AuthProfileRefreshFailureAcknowledged(this.parent);

  @override
  List<Object?> get props => [parent];
}

class AuthStaffLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthStaffLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final String? fcmToken;
  final String? deviceType;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.fcmToken,
    this.deviceType,
  });

  @override
  List<Object?> get props => [username, password, fcmToken, deviceType];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthDeleteAccountRequested extends AuthEvent {
  final String reason;

  const AuthDeleteAccountRequested(this.reason);

  @override
  List<Object?> get props => [reason];
}

class AuthAccountDeletionRequestedAcknowledged extends AuthEvent {
  final Parent parent;

  const AuthAccountDeletionRequestedAcknowledged(this.parent);

  @override
  List<Object?> get props => [parent];
}

// ─── Signup Events ────────────────────────────────────────────────────────

class AuthVerifyCnicRequested extends AuthEvent {
  final String cnic;

  const AuthVerifyCnicRequested({required this.cnic});

  @override
  List<Object?> get props => [cnic];
}

class AuthSendSignupOtpRequested extends AuthEvent {
  final String cnic;
  final String email;
  final String password;
  final String guardianName;

  const AuthSendSignupOtpRequested({
    required this.cnic,
    required this.email,
    required this.password,
    required this.guardianName,
  });

  @override
  List<Object?> get props => [cnic, email, password, guardianName];
}

class AuthRegisterRequested extends AuthEvent {
  final String cnic;
  final String email;
  final String password;
  final String guardianName;
  final String otp;
  final String? fcmToken;
  final String? deviceType;

  const AuthRegisterRequested({
    required this.cnic,
    required this.email,
    required this.password,
    required this.guardianName,
    required this.otp,
    this.fcmToken,
    this.deviceType,
  });

  @override
  List<Object?> get props =>
      [cnic, email, password, guardianName, otp, fcmToken, deviceType];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword];
}

/// Return to signup step 1 (verify CNIC) without leaving the signup screen.
class AuthSignupResetRequested extends AuthEvent {
  const AuthSignupResetRequested();
}

/// Leave signup and return to the login form (pops the signup route).
class AuthSignupExitToLoginRequested extends AuthEvent {
  const AuthSignupExitToLoginRequested();
}

/// Emitted by [TokenInterceptor] after it silently refreshes the access token.
/// Carrying the updated [Parent] keeps [AuthBloc] (and therefore HydratedBloc)
/// in sync with [FlutterSecureStorage] so both stores always hold the same tokens.
class AuthTokenRefreshed extends AuthEvent {
  final Parent parent;

  const AuthTokenRefreshed(this.parent);

  @override
  List<Object?> get props => [parent];
}

class AuthStaffRefreshRequested extends AuthEvent {
  const AuthStaffRefreshRequested();
}

class AuthStaffTokenRefreshed extends AuthEvent {
  final StaffUser staff;

  const AuthStaffTokenRefreshed(this.staff);

  @override
  List<Object?> get props => [staff];
}
