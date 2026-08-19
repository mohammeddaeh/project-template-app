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

    // A module never takes the app down with it.
    //
    // Every throw below used to escape into `ModulesBootstrap.initializeAll`,
    // which is awaited in `main._bootstrap()` **before `runApp`** — so any
    // failure here, including the ordinary "this project has not configured
    // sync yet", produced an app that never rendered a frame. No screen, no
    // message, nothing pointing back at a flag someone flipped.
    //
    // The flag's contract is "turn the module on, or leave it off". Sync
    // failing to start is a disabled module, and the app is expected to keep
    // running without it.
    try {
      await registerSyncCore(di);
      await _applyConfig(di, config);

      // Release any stale lock left by a previous crash before starting.
      await di<SyncLock>().releaseIfStale();

      final validator = di<SyncContractValidator>();

      // Not configured yet (no contracts / executors / decorators) — already
      // logged by the validator. Leave the module off and let the app run.
      if (!validator.validatePreInitialization()) return;

      await validator.migrateAndValidateQueuedJobs();

      // **The engine starts before the repositories are swapped.**
      //
      // The order used to be the other way round, and it left a window with no
      // way out of it: a failure between decoration and `init()` produced
      // repositories that queue writes into a store nothing drains. Every save
      // would appear to succeed, forever, and nothing would ever be sent —
      // while `GetIt` registrations, once replaced, cannot be rolled back.
      //
      // Reversed, the same failure leaves the plain online repositories in
      // place: the app behaves exactly as it does with the module switched off,
      // which is a state it is designed to work in.
      await di<SyncController>().init();
      await applySyncRepositoryDecorators(di);
      validator.validatePostDecoration();

      _isInitialized = true;
      LogService.debug('SyncSDK initialized.', tag: 'SYNC');
    } catch (e, st) {
      LogService.error(
        'SyncSDK failed to initialize — module disabled, app continues. '
        'If repository decorators were applied before the failure, those '
        'repositories now read from a local store that nothing drains: treat '
        'this as a release blocker, not a warning.',
        tag: 'SYNC',
        error: e,
        stackTrace: st,
      );
      await _disposeQuietly(di);
      _isInitialized = false;
    }
  }

  /// Best-effort teardown after a failed [initialize]. Never rethrows —
  /// a failure while cleaning up a failure must not reach the app either.
  static Future<void> _disposeQuietly(GetIt di) async {
    if (!di.isRegistered<SyncController>()) return;
    try {
      await di<SyncController>().dispose();
    } catch (e) {
      LogService.warning('SyncController disposal failed: $e', tag: 'SYNC');
    }
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
