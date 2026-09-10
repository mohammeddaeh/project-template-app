import 'dart:async';
import 'dart:convert';

import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/in_app_updates/domain/app_update_settings.dart';

class AppUpdateSettingsStore {
  AppUpdateSettingsStore(this._storage);

  static const _snapshotKey = 'in_app_updates.settings_snapshot';

  final StorageService _storage;
  final StreamController<AppUpdateSettings> _changes =
      StreamController<AppUpdateSettings>.broadcast();

  Stream<AppUpdateSettings> get changes => _changes.stream;

  Future<AppUpdateSettings?> read() async {
    final raw = await _storage.readString(_snapshotKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUpdateSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      return null;
    }
  }

  Future<void> write(AppUpdateSettings settings) async {
    await _storage.writeString(_snapshotKey, jsonEncode(settings.toJson()));
    _changes.add(settings);
  }
}
