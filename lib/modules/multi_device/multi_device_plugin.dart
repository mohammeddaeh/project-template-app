import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:get_it/get_it.dart';

import 'integration/multi_device_bootstrap.dart';
import 'services/device_id_service.dart';

/// Entry point for the Multi-Device Session Module.
///
/// ## Activation
/// Set `AppFeatures.multiDevice = true` — `ModulesBootstrap` starts it, and
/// `DevicesSection` in settings opens the screen. What is and is not wired:
/// `SETUP.md`.
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
