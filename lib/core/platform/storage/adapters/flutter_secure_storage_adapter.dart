import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/storage/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [SecureStorageService] adapter backed by [FlutterSecureStorage].
///
/// - iOS: Keychain
/// - Android: Keystore (AES-256 encrypted)
///
/// Registered manually in `di/injection_module.dart` — NOT annotated with
/// `@injectable` so the generator does not try to auto-wire it.
///
/// Tokens and credentials MUST use this adapter — never [StorageService].
class FlutterSecureStorageAdapter implements SecureStorageService {
  const FlutterSecureStorageAdapter(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _wrap(() => _storage.write(key: key, value: value), key, StorageOperation.write);

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageFailure(
        operation: StorageOperation.read,
        key: key,
        message: e.toString(),
      );
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw StorageFailure(
        operation: StorageOperation.read,
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> delete(String key) =>
      _wrap(() => _storage.delete(key: key), key, StorageOperation.delete);

  @override
  Future<void> clear() =>
      _wrap(() => _storage.deleteAll(), null, StorageOperation.clear);

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw StorageFailure(
        operation: StorageOperation.read,
        key: key,
        message: e.toString(),
      );
    }
  }

  Future<void> _wrap(
    Future<void> Function() call,
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
