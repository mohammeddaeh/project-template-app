import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';

/// [StorageService] adapter backed by [Hive].
///
/// Reads are **synchronous** (after box open) — faster than SharedPreferences
/// which always awaits a platform channel round-trip.
///
/// Registered manually in `di/injection_module.dart` — NOT annotated with
/// `@injectable` so the generator does not auto-wire it.
///
/// To swap to a different backend:
/// 1. Create a new adapter implementing [StorageService].
/// 2. In `injection_module.dart`, change the `storageService` binding.
///    No other code changes needed.
class HiveStorageAdapter implements StorageService {
  HiveStorageAdapter(this._box);

  final Box<dynamic> _box;

  // ── String ──────────────────────────────────────────────────────────────────

  @override
  Future<void> writeString(String key, String value) =>
      _wrap(() => _box.put(key, value), key, StorageOperation.write);

  @override
  Future<String?> readString(String key) async => _box.get(key) as String?;

  // ── Bool ────────────────────────────────────────────────────────────────────

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      _wrap(() => _box.put(key, value), key, StorageOperation.write);

  @override
  Future<bool?> readBool(String key) async => _box.get(key) as bool?;

  // ── Int ─────────────────────────────────────────────────────────────────────

  @override
  Future<void> writeInt(String key, int value) =>
      _wrap(() => _box.put(key, value), key, StorageOperation.write);

  @override
  Future<int?> readInt(String key) async => _box.get(key) as int?;

  // ── Double ───────────────────────────────────────────────────────────────────

  @override
  Future<void> writeDouble(String key, double value) =>
      _wrap(() => _box.put(key, value), key, StorageOperation.write);

  @override
  Future<double?> readDouble(String key) async => _box.get(key) as double?;

  // ── String list ──────────────────────────────────────────────────────────────

  @override
  Future<void> writeStringList(String key, List<String> values) =>
      _wrap(() => _box.put(key, values), key, StorageOperation.write);

  @override
  Future<List<String>?> readStringList(String key) async {
    final value = _box.get(key);
    if (value == null) return null;
    return (value as List).cast<String>();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  Future<void> delete(String key) =>
      _wrap(() => _box.delete(key), key, StorageOperation.delete);

  @override
  Future<void> clear() =>
      _wrap(() => _box.clear(), null, StorageOperation.clear);

  @override
  bool containsKey(String key) => _box.containsKey(key);

  // ── Internal ─────────────────────────────────────────────────────────────────

  Future<void> _wrap(
    Future<dynamic> Function() call,
    String? key,
    StorageOperation op,
  ) async {
    try {
      await call();
    } catch (e) {
      throw StorageFailure(operation: op, key: key, message: e.toString());
    }
  }
}
