import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default [StorageService] adapter backed by [SharedPreferences].
///
/// Registered manually in `di/injection_module.dart` — NOT annotated with
/// `@injectable` so the generator does not try to auto-wire it.
///
/// To swap to a different backend (Hive, Isar, ObjectBox…):
/// 1. Create a new adapter implementing [StorageService].
/// 2. In `injection_module.dart`, change:
///    ```dart
///    StorageService storageService(...) => NewAdapter(...);
///    ```
///    No other code changes needed.
class SharedPrefsStorageAdapter implements StorageService {
  const SharedPrefsStorageAdapter(this._prefs);

  final SharedPreferences _prefs;

  // ── String ──────────────────────────────────────────────────────────────────

  @override
  Future<void> writeString(String key, String value) =>
      _wrap(() => _prefs.setString(key, value), key, StorageOperation.write);

  @override
  Future<String?> readString(String key) async => _prefs.getString(key);

  // ── Bool ────────────────────────────────────────────────────────────────────

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      _wrap(() => _prefs.setBool(key, value), key, StorageOperation.write);

  @override
  Future<bool?> readBool(String key) async => _prefs.getBool(key);

  // ── Int ─────────────────────────────────────────────────────────────────────

  @override
  Future<void> writeInt(String key, int value) =>
      _wrap(() => _prefs.setInt(key, value), key, StorageOperation.write);

  @override
  Future<int?> readInt(String key) async => _prefs.getInt(key);

  // ── Double ───────────────────────────────────────────────────────────────────

  @override
  Future<void> writeDouble(String key, double value) =>
      _wrap(() => _prefs.setDouble(key, value), key, StorageOperation.write);

  @override
  Future<double?> readDouble(String key) async => _prefs.getDouble(key);

  // ── String list ──────────────────────────────────────────────────────────────

  @override
  Future<void> writeStringList(String key, List<String> values) =>
      _wrap(() => _prefs.setStringList(key, values), key, StorageOperation.write);

  @override
  Future<List<String>?> readStringList(String key) async =>
      _prefs.getStringList(key);

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  Future<void> delete(String key) =>
      _wrap(() => _prefs.remove(key), key, StorageOperation.delete);

  @override
  Future<void> clear() =>
      _wrap(() => _prefs.clear(), null, StorageOperation.clear);

  @override
  bool containsKey(String key) => _prefs.containsKey(key);

  // ── Internal ─────────────────────────────────────────────────────────────────

  Future<void> _wrap(
    Future<bool> Function() call,
    String? key,
    StorageOperation op,
  ) async {
    try {
      await call();
    } catch (e) {
      throw StorageFailure(
        operation: op,
        key: key,
        message: e.toString(),
      );
    }
  }
}
