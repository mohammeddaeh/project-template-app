import 'package:dio/dio.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/core/infra/session/auth_event_bus.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/multi_device/config/multi_device_config.dart';
import 'package:app_template/modules/multi_device/services/device_id_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Dio interceptor added by the Multi-Device module.
///
/// Responsibilities:
///   onRequest:
///     1. Injects `X-Device-ID` header on every outgoing request.
///     2. Enriches the login request body with device context fields.
///   onResponse:
///     1. Captures `device_session_id` and `is_primary` from the login response
///        and persists them via [DeviceIdService].
///   onError:
///     1. Intercepts `401 SESSION_REVOKED` before [AuthInterceptor] can
///        treat it as a plain session expiry.
class MultiDeviceInterceptor extends Interceptor {
  MultiDeviceInterceptor(this._deviceIdService);

  final DeviceIdService _deviceIdService;

  static const String _tag = 'MULTI_DEVICE';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ── 1. X-Device-ID on every request ────────────────────────────────────
    if (_deviceIdService.deviceId.isNotEmpty) {
      options.headers[MultiDeviceConfig.headerDeviceId] =
          _deviceIdService.deviceId;
    }

    // ── 2. Enrich login request ─────────────────────────────────────────────
    if (_isLoginRequest(options)) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final body = _toMutableMap(options.data);
        body['device_id']   = _deviceIdService.deviceId;
        body['device_name'] = _deviceIdService.deviceName;
        body['platform']    = _deviceIdService.platform;
        body['app_version'] = packageInfo.version;
        // fcm_token is optional — inject here if your project has FCM set up:
        // body['fcm_token'] = await FirebaseMessaging.instance.getToken();
        options.data = body;
        LogService.debug('Login request enriched with device context.', tag: _tag);
      } catch (e) {
        LogService.warning('Could not enrich login request: $e', tag: _tag);
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // ── Capture session info from login response ─────────────────────────────
    if (_isLoginRequest(response.requestOptions) &&
        response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final sessionId = data['device_session_id'] as String?;
        final isPrimary = data['is_primary'] as bool? ?? false;
        if (sessionId != null) {
          await _deviceIdService.saveSession(
            deviceSessionId: sessionId,
            isPrimary: isPrimary,
          );
          LogService.debug(
            'Session saved: id=$sessionId isPrimary=$isPrimary',
            tag: _tag,
          );
        }
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final body = err.response?.data;
      final code = body is Map ? body['code'] as String? : null;

      if (code == 'SESSION_REVOKED') {
        LogService.info(
          'SESSION_REVOKED received — firing sessionRevoked event.',
          tag: _tag,
        );
        // Clear local session state before propagating.
        _deviceIdService.clearSession();
        AuthEventBus.instance.emit(AuthEvent.sessionRevoked);

        // Stop the error here — AuthInterceptor must not treat this
        // as a plain SESSION_EXPIRED and attempt a token refresh.
        handler.reject(err);
        return;
      }
    }

    handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isLoginRequest(RequestOptions options) =>
      options.path.endsWith(ApiUrls.login) && options.method == 'POST';

  Map<String, dynamic> _toMutableMap(dynamic data) {
    if (data is Map<String, dynamic>) return Map.from(data);
    return {};
  }
}
