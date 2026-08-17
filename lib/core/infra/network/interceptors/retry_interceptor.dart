import 'package:dio/dio.dart';
import 'package:app_template/core/infra/errors/dio_failure_mapper.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Automatically retries failed requests with exponential back-off.
///
/// ## Retryable conditions
/// - [DioExceptionType.connectionError] — transient network drop
/// - [DioExceptionType.connectionTimeout] / [DioExceptionType.receiveTimeout]
/// - HTTP 502 / 503 / 504 — the server is loaded or briefly down
/// - HTTP 408 Request Timeout
///
/// ## NOT retried
/// - HTTP 4xx (except 408) — client errors, retrying is pointless
/// - **HTTP 500 / 501 / 505** — a defect, not a wobble. The same request in one
///   second reproduces the same 500, so retrying buys nothing and costs the
///   server three times the work at the moment it is already failing. This used
///   to retry every 5xx alike.
/// - HTTP 401 — handled by [TokenRefreshInterceptor] / [AuthInterceptor]
/// - Cancelled requests ([DioExceptionType.cancel])
///
/// ## Delays
///
/// Exponential back-off — attempt 1 → 1s · attempt 2 → 2s · attempt 3 → 4s —
/// **unless the server named its own wait** in `Retry-After`, which wins.
///
/// Ignoring that header is how a client turns an overload into an outage: the
/// server answers 503 "come back in 60 seconds" and the app comes back in one,
/// then two, then four, adding load to something that just said it had too
/// much. Every client doing it at once is the stampede the header exists to
/// prevent.
///
/// A wait longer than [maxHonouredRetryAfter] is **not** slept through — the
/// failure surfaces immediately instead. Holding a request for five minutes
/// behind a spinner is worse than telling the user "try again in a few
/// minutes" and letting them decide, which is exactly what
/// [ServiceUnavailableFailure] now says.
///
/// ## Registration
/// Created manually in [InjectionModule] — NOT annotated with `@injectable`
/// to avoid circular DI dependency with [Dio].
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxHonouredRetryAfter = const Duration(seconds: 10),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration initialDelay;

  /// The longest server-requested wait this interceptor will actually sleep
  /// through. Beyond it the failure surfaces and the user chooses.
  final Duration maxHonouredRetryAfter;

  static const _retryCountKey = '_retryInterceptorCount';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (attempt < maxRetries && _isRetryable(err)) {
      final delay = _delayFor(err, attempt);

      // The server asked for longer than we are willing to hold the request.
      // Surfacing now is the honest answer: `FailureUiMapper` turns it into
      // "temporarily unavailable — try again in a few minutes" with a retry
      // the user controls, rather than a spinner that looks frozen.
      if (delay == null) {
        LogService.warning(
          'Retry-After exceeds ${maxHonouredRetryAfter.inSeconds}s — '
          'surfacing instead of holding the request',
          tag: 'RETRY',
        );
        handler.next(err);
        return;
      }

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

  /// The wait before the next attempt, or `null` to stop retrying entirely.
  ///
  /// The server's own `Retry-After` outranks the back-off curve whenever it
  /// sent one — it is the only party that knows how loaded it is.
  Duration? _delayFor(DioException err, int attempt) {
    final requested =
        DioFailureMapper.retryAfterSeconds(err.response?.headers);

    if (requested != null) {
      final wait = Duration(seconds: requested);
      return wait > maxHonouredRetryAfter ? null : wait;
    }

    return initialDelay * (1 << attempt); // 1s → 2s → 4s
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

    // Only the transient 5xx. A 500 is a defect: the identical request one
    // second later reproduces it, so retrying triples the load on a server
    // that is already failing and delays the user's error by seven seconds
    // for nothing.
    return status == 408 || status == 502 || status == 503 || status == 504;
  }
}
