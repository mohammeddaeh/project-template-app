import '../config/sync_mode.dart';

class SyncSdkConfig {
  /// Five minutes — the interval `SETUP.md` §Step 2 has always documented.
  ///
  /// It lives here rather than in `SyncController` because the controller is
  /// the *consumer* of this setting: it reads whatever `SyncSettingsStore`
  /// holds, and that store is filled from this config by
  /// `SyncSDK._applyConfig`. A number hard-coded in the controller would be
  /// unreachable from the one place a project is meant to configure sync.
  static const int defaultPeriodicIntervalSeconds = 300;

  const SyncSdkConfig({
    this.enabled = true,
    this.mode = SyncMode.active,
    this.syncEnabled = true,
    this.wifiOnly = false,
    this.periodicIntervalSeconds = defaultPeriodicIntervalSeconds,
  });

  final bool enabled;
  final SyncMode mode;
  final bool syncEnabled;
  final bool wifiOnly;

  /// Seconds between automatic sync cycles. **`null` disables the timer** —
  /// an explicit opt-out, documented in `SETUP.md`, not the default.
  ///
  /// ## Why the default is a number and not `null`
  ///
  /// It used to be `null`, and nothing about that announced itself.
  /// `ModulesBootstrap` starts the module with `const SyncSdkConfig(enabled:
  /// true)`, so the omitted argument stored `null`, and
  /// `SyncController._setupPeriodic` returned at its `seconds == null` guard
  /// **before reaching `Timer.periodic`**. `init()` still completed, the
  /// connectivity listener was still bound, no exception was thrown and no
  /// warning was logged — the module simply never synced on its own. Sync
  /// happened only on a connectivity change or a manual trigger.
  ///
  /// A default that silently disables the feature it configures is the wrong
  /// default. The opt-out stays available; it just has to be asked for.
  final int? periodicIntervalSeconds;
}
