import '../config/sync_mode.dart';

class SyncSdkConfig {
  /// Five minutes — the interval `SETUP.md` §Step 2 documents.
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
  /// `ModulesBootstrap` starts the module with `const SyncSdkConfig(enabled:
  /// true)`, so a `null` default would reach `SyncController._setupPeriodic`,
  /// which returns at its `seconds == null` guard **before reaching
  /// `Timer.periodic`**. `init()` would still complete, the connectivity
  /// listener would still be bound, nothing would throw or log — the module
  /// would simply never sync on its own, only on a connectivity change or a
  /// manual trigger.
  ///
  /// A default that silently disables the feature it configures is the wrong
  /// default. The opt-out stays available; it just has to be asked for.
  final int? periodicIntervalSeconds;
}
