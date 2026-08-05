import 'package:dio/dio.dart';
import 'interceptors.dart';

class DioClient {
  final Dio dio;
  final RateLimitNotifier rateLimitNotifier;

  DioClient._(this.dio, this.rateLimitNotifier);

  factory DioClient({
    required Future<String?> Function() getToken,
    required RateLimitNotifier rateLimitNotifier,
    String baseUrl = 'https://api.github.com',
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(getToken: getToken),
      RateLimitInterceptor(rateLimitNotifier: rateLimitNotifier),
      RetryInterceptor(dio: dio),
    ]);

    return DioClient._(dio, rateLimitNotifier);
  }
}
