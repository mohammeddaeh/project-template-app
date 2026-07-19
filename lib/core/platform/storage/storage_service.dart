import 'package:app_template/core/foundation/errors/failure.dart';

/// Central key-value storage abstraction.
///
/// ## Adapter Pattern
/// The concrete backend is registered once in `di/injection_module.dart`:
/// ```dart
/// StorageService get storage => SharedPrefsStorageAdapter(prefs);
/// // swap to Hive:
/// StorageService get storage => HiveStorageAdapter(box);
/// ```
/// All Features + Repositories depend only on this interface — zero changes
/// needed when swapping backends.
///
/// ## Multiple Backends
/// Register additional named bindings in `injection_module.dart` when the
/// project needs more than one backend simultaneously:
/// ```dart
/// @Named('cache')  StorageService get cacheStorage => HiveStorageAdapter(...);
/// @Named('prefs')  StorageService get prefsStorage => SharedPrefsStorageAdapter(...);
/// ```
///
/// ## Keys
/// Always use constants from [PersistenceKeys] — never raw string literals.
///
/// ## Error Handling
/// Implementations throw [StorageFailure] on I/O errors.
/// When called from inside `BaseRepository.handle()`, failures are
/// automatically routed through [FailureMapperRegistry].
abstract interface class StorageService {
  // ── String ──────────────────────────────────────────────────────────────────

  Future<void> writeString(String key, String value);
  Future<String?> readString(String key);

  // ── Bool ────────────────────────────────────────────────────────────────────

  Future<void> writeBool(String key, {required bool value});
  Future<bool?> readBool(String key);

  // ── Int ─────────────────────────────────────────────────────────────────────

  Future<void> writeInt(String key, int value);
  Future<int?> readInt(String key);

  // ── Double ───────────────────────────────────────────────────────────────────

  Future<void> writeDouble(String key, double value);
  Future<double?> readDouble(String key);

  // ── String list ──────────────────────────────────────────────────────────────

  Future<void> writeStringList(String key, List<String> values);
  Future<List<String>?> readStringList(String key);

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Removes the value associated with [key].
  Future<void> delete(String key);

  /// Removes **all** stored values. Use with caution.
  Future<void> clear();

  /// Returns `true` if [key] exists in the store.
  bool containsKey(String key);
}
