import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/core/platform/connectivity/connectivity_service.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

import '../config/sync_mode.dart';
import '../config/sync_settings_store.dart';

/// Why a sync cycle is not starting.
///
/// A reason rather than a bool, because "sync is not running" is the single
/// most common thing a user reports and the single hardest thing to explain
/// from a log that only ever said `false`.
enum SyncBlockReason {
  disabled,
  offline,
  waitingForWifi,
  noSession,
}

/// Decides whether a sync cycle may start.
///
/// ## Connectivity was the only question being asked
///
/// `SyncController._canSyncNow()` checked the mode, the enabled flag,
/// `isOnline`, and wifi-only. Everything else it let through — and two of those
/// omissions are expensive:
///
/// - **No session.** A full cycle runs, every job gets a 401, every job's
///   `retry_count` climbs, and jobs approach `failed` because the user's token
///   expired — not because anything was ever wrong with the write.
/// - **Captive wifi.** "Connected to wifi" is not "reachable", and the cycle
///   spends its back-off budget discovering that.
///
/// ## What is deliberately *not* checked yet, and why
///
/// | Check | Why not now |
/// |---|---|
/// | Battery level | needs a package this template does not ship. P7. |
/// | Free storage | only matters once files exist. P4.5. |
/// | Server reachable | needs a health endpoint; the backend has none. P3.6 follow-up. |
///
/// They are listed rather than silently missing: a gate that looks complete is
/// worse than one that says what it does not cover.
class SyncGate {
  const SyncGate(this._settingsStore, this._connectivity, this._session);

  final SyncSettingsStore _settingsStore;
  final Connectivity _connectivity;
  final AuthNetworkGateway _session;

  /// `null` when a cycle may run; otherwise why it may not.
  Future<SyncBlockReason?> check() async {
    final settings = await _settingsStore.getSettings();
    if (settings.mode != SyncMode.active || !settings.syncEnabled) {
      return SyncBlockReason.disabled;
    }

    // No credential means every request in the cycle is already refused. Running
    // anyway burns the retry budget of writes that are perfectly valid, and
    // pushes them toward the dead-letter state for a reason that has nothing to
    // do with them.
    final token = _session.getToken();
    if (token == null || token.isEmpty) return SyncBlockReason.noSession;

    // Reachability, not "an interface is up" — a captive portal answers the
    // second and not the first.
    if (!await ConnectivityService.isOnline()) return SyncBlockReason.offline;

    if (!settings.wifiOnly) return null;

    final current = await _connectivity.checkConnectivity();
    return current.contains(ConnectivityResult.wifi)
        ? null
        : SyncBlockReason.waitingForWifi;
  }

  /// Convenience for callers that only need the verdict — and it **logs the
  /// reason**, so "sync did nothing" is never an observation without a cause.
  Future<bool> allows({String context = 'cycle'}) async {
    final reason = await check();
    if (reason == null) return true;
    LogService.debug('Sync $context skipped — ${reason.name}.', tag: 'SYNC');
    return false;
  }
}
