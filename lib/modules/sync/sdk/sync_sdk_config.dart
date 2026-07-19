import '../config/sync_mode.dart';

class SyncSdkConfig {
  const SyncSdkConfig({
    this.enabled = true,
    this.mode = SyncMode.active,
    this.syncEnabled = true,
    this.wifiOnly = false,
    this.periodicIntervalSeconds,
  });

  final bool enabled;
  final SyncMode mode;
  final bool syncEnabled;
  final bool wifiOnly;
  final int? periodicIntervalSeconds;
}
