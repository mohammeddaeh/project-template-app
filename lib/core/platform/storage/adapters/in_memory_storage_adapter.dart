import 'package:app_template/core/platform/storage/storage_service.dart';

/// In-memory [StorageService] adapter — for unit tests only.
///
/// Usage in tests:
/// ```dart
/// getIt.registerLazySingleton<StorageService>(() => InMemoryStorageAdapter());
/// ```
///
/// Not annotated with `@injectable` intentionally — never registered in
/// production DI.
class InMemoryStorageAdapter implements StorageService {
  final Map<String, Object> _store = {};

  @override
  Future<void> writeString(String key, String value) async =>
      _store[key] = value;

  @override
  Future<String?> readString(String key) async => _store[key] as String?;

  @override
  Future<void> writeBool(String key, {required bool value}) async =>
      _store[key] = value;

  @override
  Future<bool?> readBool(String key) async => _store[key] as bool?;

  @override
  Future<void> writeInt(String key, int value) async => _store[key] = value;

  @override
  Future<int?> readInt(String key) async => _store[key] as int?;

  @override
  Future<void> writeDouble(String key, double value) async =>
      _store[key] = value;

  @override
  Future<double?> readDouble(String key) async => _store[key] as double?;

  @override
  Future<void> writeStringList(String key, List<String> values) async =>
      _store[key] = values;

  @override
  Future<List<String>?> readStringList(String key) async =>
      _store[key] as List<String>?;

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();

  @override
  bool containsKey(String key) => _store.containsKey(key);
}
