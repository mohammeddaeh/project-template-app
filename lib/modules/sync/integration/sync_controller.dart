import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_template/core/platform/connectivity/connectivity_service.dart';

import '../config/sync_mode.dart';
import '../config/sync_settings_store.dart';
import '../engine/sync_engine.dart';

/// Triggers [SyncEngine.runPendingJobs] when:
/// - Network connectivity is restored.
/// - A periodic timer fires.
/// - Caller invokes [triggerManualSync].
///
/// ✅ Uses [ConnectivityService.isOnline] (template abstraction) instead of
///    raw `internet_connection_checker` to stay within the platform layer contract.
class SyncController {
  SyncController(
    this._settingsStore,
    this._connectivity,
    this._syncEngine,
  );

  final SyncSettingsStore _settingsStore;
  final Connectivity _connectivity;
  final SyncEngine _syncEngine;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicTimer;

  Future<void> init() async {
    await _bindConnectivity();
    await _setupPeriodic();
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _periodicTimer?.cancel();
  }

  Future<void> triggerManualSync() async {
    if (await _canSyncNow()) {
      await _syncEngine.runPendingJobs();
    }
  }

  Future<void> _bindConnectivity() async {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((_) async {
      if (await _canSyncNow()) {
        await _syncEngine.runPendingJobs();
      }
    });
  }

  Future<void> _setupPeriodic() async {
    _periodicTimer?.cancel();
    final settings = await _settingsStore.getSettings();
    final seconds = settings.periodicIntervalSeconds;
    if (settings.mode != SyncMode.active ||
        !settings.syncEnabled ||
        seconds == null ||
        seconds <= 0) {
      return;
    }
    _periodicTimer = Timer.periodic(Duration(seconds: seconds), (_) async {
      if (await _canSyncNow()) {
        await _syncEngine.runPendingJobs();
      }
    });
  }

  Future<bool> _canSyncNow() async {
    final settings = await _settingsStore.getSettings();
    if (settings.mode != SyncMode.active || !settings.syncEnabled) return false;

    // Use template ConnectivityService — single platform abstraction point.
    final online = await ConnectivityService.isOnline();
    if (!online) return false;

    if (!settings.wifiOnly) return true;

    final current = await _connectivity.checkConnectivity();
    return current.contains(ConnectivityResult.wifi);
  }
}
