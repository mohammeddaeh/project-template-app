/// Symmetric encryption abstraction for protecting sensitive data at rest.
///
/// ## When to use
/// Use when data must be stored in [StorageService] (plain SharedPreferences)
/// but contains sensitive values (e.g. user profile cache, offline data).
/// Tokens and credentials belong in [SecureStorageService] — not here.
///
/// ## Adapter Pattern
/// The algorithm is registered in `di/injection_module.dart`:
/// ```dart
/// EncryptionService get encryption => AesEncryptionAdapter();
/// ```
/// Swap to a different algorithm by replacing the adapter — no feature code
/// changes needed.
///
/// ## Key Management
/// The caller is responsible for providing and storing the [secretKey].
/// A common pattern is to derive it from the user's credentials and store
/// the derived key in [SecureStorageService].
///
/// ## Contract
/// - [encrypt] and [decrypt] are synchronous — pure CPU computation.
/// - [encrypt] + [decrypt] roundtrip must be lossless.
/// - Implementations must throw [ArgumentError] for invalid key sizes.
abstract interface class EncryptionService {
  /// Encrypts [plaintext] with [secretKey].
  ///
  /// Returns a Base64-encoded string that includes the IV (initialization
  /// vector) so that [decrypt] can recover the original plaintext.
  String encrypt(String plaintext, String secretKey);

  /// Decrypts a [ciphertext] produced by [encrypt].
  ///
  /// [secretKey] must match the one used during encryption.
  /// Throws [ArgumentError] if [secretKey] is invalid, or [FormatException]
  /// if [ciphertext] is malformed.
  String decrypt(String ciphertext, String secretKey);

  /// Generates a cryptographically random key suitable for AES-256.
  ///
  /// Store the returned key in [SecureStorageService] for later use.
  String generateKey();
}
