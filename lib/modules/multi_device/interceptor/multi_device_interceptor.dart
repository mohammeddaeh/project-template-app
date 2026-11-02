import 'package:dio/dio.dart';
import 'package:app_template/modules/multi_device/config/multi_device_config.dart';
import 'package:app_template/modules/multi_device/services/device_id_service.dart';

/// Attaches this device's stable id to outgoing requests when the module is
/// active, as `X-Device-ID`.
///
/// ## What is deliberately absent
///
/// **Device fields on the login body** (`device_id` / `device_name` /
/// `platform` / `app_version`). The server's login schema has no such fields,
/// so zod would strip them silently.
///
/// **The `device_info` login label.** The server does store that one string,
/// but this interceptor only runs behind `AppFeatures.multiDevice` (`false` by
/// default), and every session needs a label. So it lives in
/// `core/platform/device/device_label_service.dart` and is attached by
/// `AuthRemoteDataSource` unconditionally. This module governs the screen, not
/// the wire.
///
/// **Reading `device_session_id` / `is_primary` off the login response.** No
/// response carries either key (see [MultiDeviceConfig]).
///
/// **A `401 SESSION_REVOKED` branch.** The server does not send that code.
/// Distinguishing "an administrator ended your session" from "your session
/// expired" needs the server to keep a tombstone for revoked sessions rather
/// than deleting the row — a server feature, not a client-side check, and not
/// built. A revoked device therefore sees the ordinary expiry path, which is
/// accurate.
class MultiDeviceInterceptor extends Interceptor {
  MultiDeviceInterceptor(this._deviceIdService);

  final DeviceIdService _deviceIdService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_deviceIdService.deviceId.isNotEmpty) {
      options.headers[MultiDeviceConfig.headerDeviceId] =
          _deviceIdService.deviceId;
    }

    handler.next(options);
  }
}
