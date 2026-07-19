import 'package:dio/dio.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Automatically retries failed requests with exponential back-off.
///
/// ## Retryable conditions
/// - [DioExceptionType.connectionError] — transient network drop
/// - [DioExceptionType.connectionTimeout] / [DioExceptionType.receiveTimeout]
/// - HTTP 5xx server errors
/// - HTTP 408 Request Timeout
///
/// ## NOT retried
/// - HTTP 4xx (except 408) — client errors, retrying is pointless
/// - HTTP 401 — handled by [TokenRefreshInterceptor] / [AuthInterceptor]
/// - Cancelled requests ([DioExceptionType.cancel])
///
/// ## Delays (exponential back-off)
/// attempt 1 → 1s · attempt 2 → 2s · attempt 3 → 4s
///
/// ## Registration
/// Created manually in [InjectionModule] — NOT annotated with `@injectable`
/// to avoid circular DI dependency with [Dio].
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration initialDelay;

  static const _retryCountKey = '_retryInterceptorCount';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (attempt < maxRetries && _isRetryable(err)) {
      final delay = initialDelay * (1 << attempt); // 1s → 2s → 4s

      LogService.warning(
        'Retry ${attempt + 1}/$maxRetries after ${delay.inSeconds}s '
        '— ${err.requestOptions.method} ${err.requestOptions.path}',
        tag: 'RETRY',
      );

      await Future<void>.delayed(delay);
      err.requestOptions.extra[_retryCountKey] = attempt + 1;

      try {
        final response = await _dio.fetch<dynamic>(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }

    handler.next(err);
  }

  static bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.cancel) return false;

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    final status = err.response?.statusCode;
    if (status == null) return false;

    // 401 is handled by TokenRefreshInterceptor — don't interfere
    if (status == 401) return false;

    return status == 408 || status >= 500;
  }
}
