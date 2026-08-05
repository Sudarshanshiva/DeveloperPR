import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final String username;

  const Authenticated({required this.user, required this.username});

  @override
  List<Object?> get props => [user, username];
}

class Unauthenticated extends AuthState {
  final String? errorMessage;

  const Unauthenticated({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
