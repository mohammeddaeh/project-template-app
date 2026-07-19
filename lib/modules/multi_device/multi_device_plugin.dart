import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:get_it/get_it.dart';

import 'integration/multi_device_bootstrap.dart';
import 'services/device_id_service.dart';

/// Entry point for the Multi-Device Session Module.
///
/// ## Activation
/// 1. Set `AppFeatures.multiDevice = true` in `app_features.dart`.
/// 2. Call in `main.dart` after `configureInjection()`:
///    ```dart
///    if (AppFeatures.multiDevice) {
///      await MultiDevicePlugin.initialize(getIt);
///    }
///    ```
///
/// ## Usage after activation
/// - Login enrichment: automatic via [MultiDeviceInterceptor].
/// - Session revocation: navigate to [ActiveDevicesScreen] from settings.
/// - FCM handling: call `getIt<DeviceNotificationHandler>().handle(data)`
///   from your FCM callback.
///
/// ## Deactivation
/// Set `AppFeatures.multiDevice = false` — zero overhead, no code changes.
abstract final class MultiDevicePlugin {
  static bool _initialized = false;

  static const String _tag = 'MULTI_DEVICE';

  static Future<void> initialize(GetIt di) async {
    if (_initialized) return;
    if (!AppFeatures.multiDevice) {
      LogService.debug(
        'MultiDevicePlugin disabled (AppFeatures.multiDevice=false).',
        tag: _tag,
      );
      return;
    }

    LogService.debug('MultiDevicePlugin initializing...', tag: _tag);

    await registerMultiDeviceCore(di);

    // Initialize device identity (generates or restores UUID).
    await di<DeviceIdService>().init();

    _initialized = true;
    LogService.debug('MultiDevicePlugin ready.', tag: _tag);
  }

  static void reset() => _initialized = false;
}
