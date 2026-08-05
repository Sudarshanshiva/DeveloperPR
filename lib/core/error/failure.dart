import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection available. Serving offline cached data.']);
}

class RateLimitFailure extends Failure {
  final int resetTimestamp;
  const RateLimitFailure(super.message, {required this.resetTimestamp});

  @override
  List<Object?> get props => [message, resetTimestamp];
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Invalid GitHub Personal Access Token or Token expired.']);
}
