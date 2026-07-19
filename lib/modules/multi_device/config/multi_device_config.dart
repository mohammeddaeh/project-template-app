/// Central configuration for the Multi-Device Session Module.
///
/// Modify [maxDevices] to change the device limit.
/// All other values are FCM payload type strings — must match backend.
abstract final class MultiDeviceConfig {
  /// Maximum number of simultaneous active sessions per user.
  static const int maxDevices = 3;

  // ── FCM payload types ─────────────────────────────────────────────────────
  static const String fcmTypeNewDeviceLogin = 'new_device_login';
  static const String fcmTypeSessionRevoked = 'session_revoked';
  static const String fcmTypeDeviceRemoved  = 'device_removed';

  // ── HTTP header ───────────────────────────────────────────────────────────
  static const String headerDeviceId = 'X-Device-ID';
}
