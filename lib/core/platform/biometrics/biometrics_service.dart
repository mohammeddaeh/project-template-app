/// Biometric authentication abstraction (fingerprint / Face ID).
///
/// ## Typical usage
/// ```dart
/// if (!await _bio.isAvailable()) return; // device doesn't support it
/// if (!await _bio.isEnrolled())  return; // no biometrics registered
///
/// final authenticated = await _bio.authenticate('Confirm your identity');
/// if (authenticated) { /* unlock sensitive UI */ }
/// ```
///
/// ## Integration with SecureStorage
/// Biometrics only VERIFY identity — the actual credentials (tokens) live
/// in [SecureStorageService]. On successful authentication, read the token
/// from secure storage and proceed.
///
/// Registered in `di/injection_module.dart`.
abstract interface class BiometricsService {
  /// Returns `true` if the device hardware supports biometric authentication
  /// AND the OS has biometrics configured.
  Future<bool> isAvailable();

  /// Returns `true` if the user has enrolled at least one biometric credential
  /// (fingerprint or face).
  Future<bool> isEnrolled();

  /// Prompts the OS biometric dialog with [localizedReason] as the message.
  ///
  /// Returns `true` if authentication succeeded, `false` if the user cancelled
  /// or failed.
  ///
  /// [localizedReason] should be translated before passing (use `.tr()`).
  Future<bool> authenticate(String localizedReason);
}
