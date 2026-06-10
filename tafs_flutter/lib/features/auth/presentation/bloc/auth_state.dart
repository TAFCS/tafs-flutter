import 'package:equatable/equatable.dart';
import '../../domain/entities/parent.dart';

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
