class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class RateLimitException implements Exception {
  final String message;
  final int resetTimestamp;
  RateLimitException(this.message, {required this.resetTimestamp});
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication failed']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No Network Connection']);
}

class QuotaExceededException implements Exception {
  final String message;
  QuotaExceededException([this.message = 'Daily free AI quota exceeded']);
}

