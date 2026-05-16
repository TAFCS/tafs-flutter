import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthRefreshRequested extends AuthEvent {}

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

// ─── Signup Events ────────────────────────────────────────────────────────

class AuthVerifyCnicRequested extends AuthEvent {
  final String cnic;

  const AuthVerifyCnicRequested({required this.cnic});

  @override
  List<Object?> get props => [cnic];
}

class AuthRegisterRequested extends AuthEvent {
  final String cnic;
  final String email;
  final String password;
  final String? fcmToken;
  final String? deviceType;

  const AuthRegisterRequested({
    required this.cnic,
    required this.email,
    required this.password,
    this.fcmToken,
    this.deviceType,
  });

  @override
  List<Object?> get props => [cnic, email, password, fcmToken, deviceType];
}

class AuthSignupResetRequested extends AuthEvent {
  const AuthSignupResetRequested();
}
