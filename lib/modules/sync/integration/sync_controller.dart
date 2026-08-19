import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_template/core/platform/connectivity/connectivity_service.dart';

import '../config/sync_mode.dart';
import '../config/sync_settings_store.dart';
import '../engine/sync_engine.dart';
import 'sync_gate.dart';

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
    this._gate,
  );

  final SyncSettingsStore _settingsStore;
  final Connectivity _connectivity;
  final SyncEngine _syncEngine;
  final SyncGate _gate;

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

  /// Delegates to [SyncGate], which asks more than connectivity — and says why
  /// when it refuses. See that class for what it checks and what it does not.
  Future<bool> _canSyncNow() => _gate.allows();
}
