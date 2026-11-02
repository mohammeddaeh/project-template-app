import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/remote_config/adapters/firebase_remote_config_adapter.dart';
import 'package:app_template/modules/remote_config/remote_config_service.dart';
import 'package:get_it/get_it.dart';

/// Entry point for the remote-config module.
///
/// ## Setup — see `SETUP.md` in this folder.
///
/// ## Usage
/// ```dart
/// // main.dart
/// await RemoteConfigPlugin.initialize(getIt, defaults: {
///   'new_payment_flow': false,
///   'min_app_version': '1.0.0',
///   'banner_text': '',
/// });
///
/// // Anywhere in the app:
/// final enabled = getIt<RemoteConfigService>().getBool('new_payment_flow');
/// ```
abstract final class RemoteConfigPlugin {
  static bool _initialized = false;

  /// Initialises Firebase Remote Config and registers [RemoteConfigService].
  ///
  /// [defaults] — local fallback values used when the device is offline or
  /// the key has not been set in the Firebase console yet.
  ///
  /// [minimumFetchInterval] — how often new values are fetched.
  /// Use `Duration.zero` in debug/staging for instant updates.
  static Future<void> initialize(
    GetIt di, {
    Map<String, dynamic> defaults = const {},
    Duration minimumFetchInterval = const Duration(hours: 12),
  }) async {
    if (_initialized) return;

    final adapter = FirebaseRemoteConfigAdapter(
      defaults: defaults,
      minimumFetchInterval: minimumFetchInterval,
    );

    await adapter.init();

    di.registerSingleton<RemoteConfigService>(adapter);

    _initialized = true;
    LogService.info('RemoteConfigPlugin initialized', tag: 'RCONFIG');
  }
}

/// الاسم السابق — يبقى ليُصرَّف `modules_bootstrap.dart` بمشروعٍ قائم حتى يُحدَّث.
@Deprecated('Use RemoteConfigPlugin')
typedef RemoteConfigModule = RemoteConfigPlugin;
