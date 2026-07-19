/// Configuration passed to [PushNotificationsModule.initialize].
///
/// [tokenStorageKey] — the [SecureStorageService] key used to persist the
/// FCM device token. Defaults to `'fcm_token'`.
///
/// [onTokenRefresh] — called whenever FCM issues a new token.
/// Typical use: send the token to your backend.
///
/// [requestPermissionOnInit] — when `true` (default) the module asks
/// the user for notification permission during initialization.
final class PushNotificationsConfig {
  const PushNotificationsConfig({
    this.tokenStorageKey = 'fcm_token',
    this.onTokenRefresh,
    this.requestPermissionOnInit = true,
  });

  final String tokenStorageKey;

  /// Callback invoked with the fresh token every time FCM rotates it.
  /// Use this to send the token to your API.
  final Future<void> Function(String token)? onTokenRefresh;

  final bool requestPermissionOnInit;
}
