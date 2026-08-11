import 'package:dio/dio.dart';
import 'package:app_template/modules/multi_device/config/multi_device_config.dart';
import 'package:app_template/modules/multi_device/services/device_id_service.dart';

/// Attaches this device's stable id to outgoing requests when the module is
/// active, as `X-Device-ID`.
///
/// ## What was removed (2026-08-11)
///
/// **The `device_id` / `device_name` / `platform` / `app_version` body fields.**
/// The server's login schema has no such fields, so zod stripped all four
/// silently — the enrichment ran on every sign-in and reached nothing.
///
/// **The `device_info` login label (removed a second time, later the same
/// day).** Replacing the four fields with the one string the server does store
/// was correct, but putting it *here* left it behind
/// `AppFeatures.multiDevice`, which is `false` by default — so every session a
/// default build opened was still labelled with Dio's `User-Agent`. It now
/// lives in `core/platform/device/device_label_service.dart` and is attached by
/// `AuthRemoteDataSource` unconditionally. This module governs the screen, not
/// the wire.
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

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (_deviceIdService.deviceId.isNotEmpty) {
      options.headers[MultiDeviceConfig.headerDeviceId] =
          _deviceIdService.deviceId;
    }

    handler.next(options);
  }
}
