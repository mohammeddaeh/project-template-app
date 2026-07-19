import 'sync_mode.dart';

class SyncSettings {
  const SyncSettings({
    required this.mode,
    required this.syncEnabled,
    required this.wifiOnly,
    required this.periodicIntervalSeconds,
  });

  final SyncMode mode;
  final bool syncEnabled;
  final bool wifiOnly;
  final int? periodicIntervalSeconds;

  bool get isDisabledMode => mode == SyncMode.disabled;
  bool get isPassiveMode => mode == SyncMode.passive;
  bool get isActiveMode => mode == SyncMode.active;
}
