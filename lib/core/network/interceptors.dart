import 'dart:async';
import 'package:dio/dio.dart';

class RateLimitInfo {
  final int limit;
  final int remaining;
  final int resetTimestamp;

  RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.resetTimestamp,
  });

  bool get isLow => remaining > 0 && remaining <= 50;
  bool get isExceeded => remaining == 0;
}

class RateLimitNotifier {
  final _controller = StreamController<RateLimitInfo>.broadcast();
  Stream<RateLimitInfo> get stream => _controller.stream;
  RateLimitInfo? currentInfo;

  void update(RateLimitInfo info) {
    currentInfo = info;
    _controller.add(info);
  }

  void dispose() {
    _controller.close();
  }
}

class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getToken;

  AuthInterceptor({required this.getToken});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/vnd.github.v3+json';
    options.headers['User-Agent'] = 'GitHub-PR-Dashboard-Flutter';
    handler.next(options);
  }
}

class RateLimitInterceptor extends Interceptor {
  final RateLimitNotifier rateLimitNotifier;

  RateLimitInterceptor({required this.rateLimitNotifier});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _extractRateLimitHeaders(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _extractRateLimitHeaders(err.response!.headers);
    }
    handler.next(err);
  }

  void _extractRateLimitHeaders(Headers headers) {
    final limitStr = headers.value('x-ratelimit-limit');
    final remainingStr = headers.value('x-ratelimit-remaining');
    final resetStr = headers.value('x-ratelimit-reset');

    if (limitStr != null && remainingStr != null && resetStr != null) {
      final limit = int.tryParse(limitStr) ?? 5000;
      final remaining = int.tryParse(remainingStr) ?? 5000;
      final reset = int.tryParse(resetStr) ?? 0;

      rateLimitNotifier.update(
        RateLimitInfo(
          limit: limit,
          remaining: remaining,
          resetTimestamp: reset,
        ),
      );
    }
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 2});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final statusCode = response?.statusCode;

    final requestOptions = err.requestOptions;
    final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;

    if (statusCode != null && statusCode >= 500 && retryCount < maxRetries) {
      requestOptions.extra['retry_count'] = retryCount + 1;
      final delay = Duration(milliseconds: 1000 * (retryCount + 1));
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }

    return handler.next(err);
  }
}
