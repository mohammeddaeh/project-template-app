/// Configuration for the Multi-Device Session Module.
///
/// ## What was removed here, and why (2026-08-11)
///
/// **`maxDevices = 3`** — a cap with no defined behaviour for the fourth
/// device. Both possible meanings were worse than no cap:
///
/// - *Refuse the new sign-in*: someone holding three older devices cannot get
///   in from a new one, sees a refusal they cannot act on, and concludes the
///   account is broken. Losing three phones would lock them out entirely until
///   an administrator intervened.
/// - *Evict the oldest*: safe, but it is an anti-account-sharing **business
///   policy**, not account security — and this template serves more than one
///   application. A policy belongs to the app that needs it.
///
/// So the module now does what its name promises and nothing more: show where
/// this account is signed in, and end any of those sessions. A cap can be added
/// later as a server-side policy without touching this screen.
///
/// **`isPrimary`** — the rule that only the first-ever device may revoke
/// others. It fails in exactly the situation the feature exists for: lose the
/// primary phone and you can no longer revoke anything, from anywhere. Any
/// session may now end any session **of the same account**, which the server
/// enforces by ownership rather than by seniority.
abstract final class MultiDeviceConfig {
  // ── FCM payload types ─────────────────────────────────────────────────────
  //
  // ⚠️ RESERVED — nothing sends these yet. The backend has no push integration
  // and no endpoint emits them. They are kept because a "signed in on a new
  // device" notification is a natural extension, and named constants are how
  // that lands consistently — but until a sender exists, treat any code
  // branching on them as unreachable.
  static const String fcmTypeNewDeviceLogin = 'new_device_login';
  static const String fcmTypeSessionRevoked = 'session_revoked';
  static const String fcmTypeDeviceRemoved = 'device_removed';

  // ── HTTP header ───────────────────────────────────────────────────────────
  /// Sent on every request when the module is active.
  ///
  /// The server currently ignores it. Kept because it costs one header and it
  /// is what a future per-device policy (a cap, or "this exact device was
  /// revoked") would key on — and a device identity that only starts being
  /// recorded the day it is needed can answer nothing about the past.
  static const String headerDeviceId = 'X-Device-ID';
}
