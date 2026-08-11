import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_template/core/infra/network/rest/api_urls.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/multi_device/config/multi_device_config.dart';
import 'package:app_template/modules/multi_device/services/device_id_service.dart';

/// Attaches device identity to outgoing requests when the module is active.
///
/// ## What it does
/// - Adds `X-Device-ID` to every request.
/// - Labels the sign-in so the sessions screen has something a person can
///   recognise — otherwise every row reads "unknown device" and the screen
///   cannot answer the question it exists for.
///
/// ## What was removed (2026-08-11)
///
/// **The `device_id` / `device_name` / `platform` / `app_version` body fields.**
/// The server's login schema has no such fields, so zod stripped all four
/// silently — the enrichment ran on every sign-in and reached nothing. They are
/// replaced by the single `device_info` string the server does store.
///
/// **The login-response capture of `device_session_id` / `is_primary`.** Neither
/// key exists in any response; both were read as null on every login. The
/// seniority rule they served is gone with them (see [MultiDeviceConfig]).
///
/// **The `401 SESSION_REVOKED` branch.** No endpoint has ever emitted that
/// code. Distinguishing "an administrator ended your session" from "your
/// session expired" needs the server to keep a tombstone for revoked sessions
/// rather than deleting the row — a real feature, not a client-side check, and
/// deliberately not built yet. Until it is, a revoked device sees the ordinary
/// expiry path, which is accurate.
class MultiDeviceInterceptor extends Interceptor {
  MultiDeviceInterceptor(this._deviceIdService);

  final DeviceIdService _deviceIdService;

  static const String _tag = 'MULTI_DEVICE';

  /// Resolved once — `PackageInfo.fromPlatform()` reads a platform channel, and
  /// the version cannot change while the process is alive.
  String? _appVersion;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_deviceIdService.deviceId.isNotEmpty) {
      options.headers[MultiDeviceConfig.headerDeviceId] =
          _deviceIdService.deviceId;
    }

    if (_isLoginRequest(options)) {
      try {
        options.data = {
          ..._toMutableMap(options.data),
          'device_info': await _deviceLabel(),
        };
      } catch (e) {
        // Never blocks the sign-in. The label is a convenience for a screen the
        // user may never open; failing to build it must not cost them the
        // ability to log in.
        LogService.warning('Could not label this device: $e', tag: _tag);
      }
    }

    handler.next(options);
  }

  /// e.g. `Samsung SM-G991B · android · v1.2.0`.
  ///
  /// Deliberately human-shaped rather than structured: the server stores it
  /// verbatim as free text and never parses it, so any structure would be
  /// invented on both ends for nothing.
  Future<String> _deviceLabel() async {
    _appVersion ??= (await PackageInfo.fromPlatform()).version;
    return [
      _deviceIdService.deviceName,
      _deviceIdService.platform,
      'v$_appVersion',
    ].join(' · ');
  }

  bool _isLoginRequest(RequestOptions options) =>
      options.path.endsWith(ApiUrls.login) && options.method == 'POST';

  Map<String, dynamic> _toMutableMap(dynamic data) {
    if (data is Map<String, dynamic>) return Map.from(data);
    return {};
  }
}
