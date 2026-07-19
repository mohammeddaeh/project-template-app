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

    // If THIS request is the refresh call itself — refresh failed
    if (err.requestOptions.extra['_isRefreshRequest'] == true) {
      LogService.error('Token refresh request returned 401', tag: 'TOKEN-REFRESH');
      return _handleRefreshFailure(err, handler);
    }

    try {
      if (_refreshCompleter != null) {
        // Another request is already refreshing — wait for it to complete
        LogService.info('Waiting for in-progress token refresh…', tag: 'TOKEN-REFRESH');
        await _refreshCompleter!.future;
      } else {
        // Start the refresh
        _refreshCompleter = Completer<void>();
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
      await _handleRefreshFailure(err, handler);
    }
  }

  Future<void> _handleRefreshFailure(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    LogService.error('Token refresh failed — session expired.', tag: 'TOKEN-REFRESH');
    await _refreshGateway.onRefreshFailed();
    AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    handler.next(err);
  }
}
