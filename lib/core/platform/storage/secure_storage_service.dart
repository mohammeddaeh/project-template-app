/// Secure key-value storage for sensitive data (tokens, credentials).
///
/// ## Why separate from [StorageService]?
/// - Uses OS-level encryption (Keychain on iOS, Keystore on Android).
/// - Tokens MUST NEVER be stored in [StorageService] (SharedPreferences
///   stores in plain text on the device file system).
///
/// ## Adapter Pattern
/// Registered once in `di/injection_module.dart`:
/// ```dart
/// SecureStorageService get secureStorage => FlutterSecureStorageAdapter(...);
/// ```
///
/// ## Keys
/// Always use constants from [PersistenceKeys] — never raw string literals.
///
/// ## Error Handling
/// Implementations throw [StorageFailure] on I/O errors.
abstract interface class SecureStorageService {
  /// Writes [value] for [key], overwriting any existing value.
  Future<void> write(String key, String value);

  /// Returns the value for [key], or `null` if absent.
  Future<String?> read(String key);

  /// Returns all stored key-value pairs.
  Future<Map<String, String>> readAll();

  /// Removes the value associated with [key].
  Future<void> delete(String key);

  /// Removes **all** stored values. Use with caution.
  Future<void> clear();

  /// Returns `true` if [key] exists in the secure store.
  Future<bool> containsKey(String key);
}
