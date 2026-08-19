import 'dart:async';

import 'package:dio/dio.dart';
import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/core/foundation/contracts/token_refresh_gateway.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// Silently refreshes the access token on 401 and retries the original request.
///
/// ## Flow
/// ```
/// Request → 401
///   │
///   ▼  (first 401 — starts refresh)
/// TokenRefreshGateway.refresh()
///   ├─ Success → save new token → retry all queued requests ✅
///   └─ Failure → onRefreshFailed() → AuthEventBus.sessionExpired ❌
///
/// (concurrent 401s while refresh is in progress → queued, then retried)
/// ```
///
/// ## Race-condition safety
/// A single [Completer] serialises concurrent 401s: the first caller performs
/// the refresh while all others wait. When the refresh completes, every
/// queued request is retried with the new token (injected by [AuthInterceptor]).
///
/// ## Registration
/// Created manually in [InjectionModule] with the live [Dio] instance.
/// NOT registered via injectable — circular dependency with Dio.
/// Wired manually in [InjectableModule.dioInstance] only when
/// [TokenRefreshGateway] is registered.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(
    this._dio,
    this._refreshGateway,
    this._authGateway,
  );

  final Dio _dio;
  final TokenRefreshGateway _refreshGateway;
  final AuthNetworkGateway _authGateway;

  /// Non-null while a refresh is in flight — other 401 handlers wait on this.
  Completer<void>? _refreshCompleter;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only intercept 401 when the user has a token (skip unauthenticated calls)
    if (err.response?.statusCode != 401 || _authGateway.getToken() == null) {
      return handler.next(err);
    }

    // If THIS request is the refresh call itself — the server answered 401 to
    // the credential's own renewal, which is as terminal as an answer gets.
    if (err.requestOptions.extra['_isRefreshRequest'] == true) {
      LogService.error('Token refresh request returned 401', tag: 'TOKEN-REFRESH');
      return _handleRefreshFailure(err, handler, cause: err);
    }

    try {
      if (_refreshCompleter != null) {
        // Another request is already refreshing — wait for it to complete
        LogService.info('Waiting for in-progress token refresh…', tag: 'TOKEN-REFRESH');
        await _refreshCompleter!.future;
      } else {
        // Start the refresh
        _refreshCompleter = Completer<void>();

        // Attach a listener immediately, because there may never be another
        // one. Only *concurrent* 401s await this future — the common case is a
        // single request refreshing alone — and `completeError` on a future
        // nobody is listening to escapes as an unhandled asynchronous error,
        // straight past the `catch` below into `runZonedGuarded` in `main`.
        //
        // The failure is still handled correctly here; the zone just also sees
        // it, and reports a refused token refresh as if the app had crashed.
        // Surfaced by `test/sync/offline_session_test.dart`, which is the only
        // way it was ever going to be: in the app the noise is one more line in
        // a log that already has a real error in it.
        unawaited(_refreshCompleter!.future.catchError((Object _) {}));

        LogService.info('Starting token refresh…', tag: 'TOKEN-REFRESH');

        await _refreshGateway.refresh();

        _refreshCompleter!.complete();
        _refreshCompleter = null;
        LogService.info('Token refresh succeeded.', tag: 'TOKEN-REFRESH');
      }

      // Retry the original request — AuthInterceptor injects the new token
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      _refreshCompleter?.completeError(e);
      _refreshCompleter = null;
      await _handleRefreshFailure(err, handler, cause: e);
    }
  }

  /// Ends the refresh attempt — and **decides whether the session survives it.**
  ///
  /// ## "Refused" and "never arrived" are opposite facts
  ///
  /// This method used to clear the session for both. Every failure reaching the
  /// `catch` above — a 401 on the refresh call, a dropped connection, a
  /// cancelled request — took the same path: clear the token, clear the cached
  /// user, emit [AuthEvent.sessionExpired], land the user on the login screen.
  ///
  /// So a phone that lost signal in the second between a 401 and its renewal was
  /// signed out. On a device holding queued offline work that is not a
  /// nuisance: the user is ejected to a login screen they cannot pass — no
  /// network to log in with — while a morning's unsynced writes sit behind an
  /// account the app no longer believes in.
  ///
  /// The rule now is one question: **did a server answer?**
  Future<void> _handleRefreshFailure(
    DioException err,
    ErrorInterceptorHandler handler, {
    required Object cause,
  }) async {
    if (_isTransportFailure(cause)) {
      // Nothing was refused, because nothing was heard. Keep the token, keep
      // the cached user, keep every permission already granted. The next
      // request retries, and the one after that.
      LogService.warning(
        'Token refresh could not be delivered — session kept. '
        'This is a connectivity failure, not a refusal: $cause',
        tag: 'TOKEN-REFRESH',
      );
      AuthEventBus.instance.emit(AuthEvent.sessionRefreshDeferred);
      return handler.next(err);
    }

    LogService.error(
      'Token refresh refused — local session cleared.',
      tag: 'TOKEN-REFRESH',
      error: cause,
    );
    await _refreshGateway.onRefreshFailed();
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    handler.next(err);
  }

  /// `true` when no server ever answered.
  ///
  /// The test is deliberately the **presence of a response**, not a list of
  /// [DioExceptionType] values: a list has to be revisited every time Dio adds
  /// a variant, and the one forgotten variant signs users out. "The server
  /// spoke" is the property that actually matters, and it has one representation.
  ///
  /// A cancelled request also lands here, correctly — abandoning a screen
  /// mid-request must never end a session.
  ///
  /// Anything else — including a [StateError] from the gateway when there is no
  /// token to rotate, or a response carrying no token — is terminal: the client
  /// holds a credential it cannot renew, and pretending otherwise leaves it
  /// retrying forever against a session that is gone.
  static bool _isTransportFailure(Object error) =>
      error is DioException && error.response == null;
}
