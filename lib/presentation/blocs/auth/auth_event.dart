import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SubmitUsernameEvent extends AuthEvent {
  final String username;
  const SubmitUsernameEvent(this.username);

  @override
  List<Object?> get props => [username];
}

class LogoutEvent extends AuthEvent {}
