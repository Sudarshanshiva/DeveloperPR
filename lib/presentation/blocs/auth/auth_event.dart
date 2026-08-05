import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SubmitTokenEvent extends AuthEvent {
  final String token;
  const SubmitTokenEvent(this.token);

  @override
  List<Object?> get props => [token];
}

class LogoutEvent extends AuthEvent {}
