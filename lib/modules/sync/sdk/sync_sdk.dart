import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:get_it/get_it.dart';

import '../config/sync_settings_store.dart';
import '../integration/sync_bootstrap.dart';
import '../integration/sync_controller.dart';
import '../integration/sync_lock.dart';
import '../validation/sync_contract_validator.dart';
import 'sync_sdk_config.dart';

/// Entry point for the offline-first sync module.
///
/// ## Initialization (in `app.dart` > `_AppState.initState`):
/// ```dart
/// await SyncSDK.initialize(
///   SyncSdkConfig(
///     enabled: AppFeatures.offlineSync,
///     mode: SyncMode.active,
///   ),
///   GetIt.instance,
/// );
/// ```
///
/// ## Shutdown (in `AppLifecycle.detached`):
/// ```dart
/// await SyncSDK.shutdown(GetIt.instance);
/// ```
class SyncSDK {
  SyncSDK._();

  static bool _isInitialized = false;

  static Future<void> initialize(
    SyncSdkConfig config,
    GetIt di,
  ) async {
    if (_isInitialized) return;

    // Hard gate: if the feature flag is off, exit immediately — zero overhead.
    if (!config.enabled || !AppFeatures.offlineSync) {
      LogService.debug(
        'SyncSDK disabled (AppFeatures.offlineSync=false or config.enabled=false).',
        tag: 'SYNC',
      );
      return;
    }

    LogService.debug('SyncSDK initializing...', tag: 'SYNC');

    await registerSyncCore(di);
    await _applyConfig(di, config);

    // Release any stale lock left by a previous crash before starting.
    await di<SyncLock>().releaseIfStale();

    di<SyncContractValidator>().validatePreInitialization();
    await di<SyncContractValidator>().migrateAndValidateQueuedJobs();
    await applySyncRepositoryDecorators(di);
    di<SyncContractValidator>().validatePostDecoration();
    await di<SyncController>().init();

    _isInitialized = true;
    LogService.debug('SyncSDK initialized.', tag: 'SYNC');
  }

  static Future<void> shutdown(GetIt di) async {
    if (!_isInitialized) return;
    if (di.isRegistered<SyncController>()) {
      await di<SyncController>().dispose();
    }
    _isInitialized = false;
    LogService.debug('SyncSDK shut down.', tag: 'SYNC');
  }

  static Future<void> _applyConfig(GetIt di, SyncSdkConfig config) async {
    final store = di<SyncSettingsStore>();
    await store.setMode(config.mode);
    await store.setSyncEnabled(config.syncEnabled);
    await store.setWifiOnly(config.wifiOnly);
    await store.setPeriodicIntervalSeconds(config.periodicIntervalSeconds);
  }
}
