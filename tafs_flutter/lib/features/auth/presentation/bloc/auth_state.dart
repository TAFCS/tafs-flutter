import 'package:equatable/equatable.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/staff_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Parent parent;

  const AuthAuthenticated(this.parent);

  @override
  List<Object> get props => [parent];
}

class AuthAuthenticatedStaff extends AuthState {
  final StaffUser staff;

  const AuthAuthenticatedStaff(this.staff);

  @override
  List<Object> get props => [staff];
}

/// One-shot state when profile refresh fails; keeps last known [parent] for UI.
class AuthProfileRefreshFailed extends AuthState {
  final Parent parent;
  final String message;

  const AuthProfileRefreshFailed({
    required this.parent,
    required this.message,
  });

  @override
  List<Object> get props => [parent, message];
}

/// One-shot state after parent submits account deletion request (stays logged in).
class AuthAccountDeletionRequested extends AuthState {
  final Parent parent;

  const AuthAccountDeletionRequested(this.parent);

  @override
  List<Object> get props => [parent];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

// ─── Signup States ────────────────────────────────────────────────────────

class SignupInitial extends AuthState {}

class SignupCnicVerifying extends AuthState {}

class SignupCnicValid extends AuthState {
  final String cnic;
  final String guardianName;

  const SignupCnicValid({required this.cnic, required this.guardianName});

  @override
  List<Object> get props => [cnic, guardianName];
}

class SignupCnicInvalid extends AuthState {
  final String message;

  const SignupCnicInvalid(this.message);

  @override
  List<Object> get props => [message];
}

class SignupRegistering extends AuthState {}

class SignupRegisterFailed extends AuthState {
  final String message;
  final String cnic;
  final String guardianName;

  const SignupRegisterFailed({
    required this.message,
    required this.cnic,
    required this.guardianName,
  });

  @override
  List<Object> get props => [message, cnic, guardianName];
}

class SignupSuccess extends AuthState {
  final Parent parent;

  const SignupSuccess(this.parent);

  @override
  List<Object> get props => [parent];
}

// ─── Signup OTP States ─────────────────────────────────────────────────────

class SignupOtpSending extends AuthState {}

class SignupOtpSent extends AuthState {
  final String cnic;
  final String email;
  final String password;
  final String guardianName;

  const SignupOtpSent({
    required this.cnic,
    required this.email,
    required this.password,
    required this.guardianName,
  });

  @override
  List<Object> get props => [cnic, email, password, guardianName];
}

class SignupOtpFailed extends AuthState {
  final String message;
  final String cnic;
  final String guardianName;

  const SignupOtpFailed({
    required this.message,
    required this.cnic,
    required this.guardianName,
  });

  @override
  List<Object> get props => [message, cnic, guardianName];
}

// ─── Forgot / Reset Password States ────────────────────────────────────────

class ForgotPasswordSending extends AuthState {}

class ForgotPasswordSent extends AuthState {}

class ForgotPasswordFailed extends AuthState {
  final String message;

  const ForgotPasswordFailed(this.message);

  @override
  List<Object> get props => [message];
}

class ResetPasswordSubmitting extends AuthState {}

class ResetPasswordSuccess extends AuthState {}

class ResetPasswordFailed extends AuthState {
  final String message;

  const ResetPasswordFailed(this.message);

  @override
  List<Object> get props => [message];
}

// ─── Change Password States (logged in) ─────────────────────────────────────

class ChangePasswordSuccess extends AuthState {
  const ChangePasswordSuccess();
}

class ChangePasswordFailed extends AuthState {
  final String message;

  const ChangePasswordFailed(this.message);

  @override
  List<Object> get props => [message];
}
