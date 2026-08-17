import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/core/foundation/contracts/locale_provider.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthInterceptor extends Interceptor {
  final AuthNetworkGateway _gateway;
  final LocaleProvider _localeProvider;

  /// Whether this interceptor clears the session and emits
  /// [AuthEvent.sessionExpired] on a 401.
  ///
  /// Set to `false` by the composition root ([InjectableModule.dioInstance])
  /// when a [TokenRefreshInterceptor] is wired — that layer then owns 401
  /// recovery (silent refresh + retry) and only signals expiry when the
  /// refresh itself fails. This prevents Auth from pre-empting the refresh.
  bool handlesSessionExpiry = true;

  AuthInterceptor(this._gateway, this._localeProvider);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = _gateway.getToken();

    if (token != null) {
      options.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept-language': _localeProvider.languageCode,
      });
    }

    if (!handler.isCompleted) handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (handlesSessionExpiry &&
        err.response?.statusCode == 401 &&
        _gateway.getToken() != null) {
      _gateway.clearSession();
      AuthEventBus.instance.emit(AuthEvent.sessionExpired);
    }

    // A 403 the client did not expect: it drew a control the server refuses, so
    // the permission set it holds is out of date. **Fires** the re-read rather
    // than performing it — an interceptor awaiting a request on the same Dio
    // instance would deadlock itself.
    //
    // `permission_missing` specifically, not every 403: an account-status
    // refusal (`disabled`, `pending_verification`) is also a 403, and
    // re-reading permissions would answer nothing about it.
    if (err.response?.statusCode == 403 && _isPermissionRefusal(err)) {
      AuthEventBus.instance.emit(AuthEvent.permissionsStale);
    }

    if (!handler.isCompleted) handler.next(err);
  }

  /// The server names its refusals with `data.message_key` — the discriminator
  /// a client branches on instead of matching free text, which changes with the
  /// reader's language on every request.
  bool _isPermissionRefusal(DioException err) {
    final body = err.response?.data;
    if (body is! Map) return false;
    final data = body['data'];
    return data is Map && data['message_key'] == 'permission_missing';
  }
}
