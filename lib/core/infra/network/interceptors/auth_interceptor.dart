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

    if (!handler.isCompleted) handler.next(err);
  }
}
