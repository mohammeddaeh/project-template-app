abstract class PersistenceKeys {
  static const String token = 'Token';
  static const String fcmToken = 'FcmToken';

  // ── Settings ───────────────────────────────────────────────────────────────
  static const String notificationsEnabled = 'notifications_enabled';
  static const String selectedFontKey      = 'selected_font_key';

  // ── Multi-Device module ────────────────────────────────────────────────────
  /// Stable UUID identifying this device. Generated once on first launch.
  static const String deviceId = 'device_id';

  /// The device_session_id returned by the server after login.
  static const String deviceSessionId = 'device_session_id';

  /// True if this device is the primary (first-ever login) device for the account.
  static const String deviceIsPrimary = 'device_is_primary';

  // ── Navigation ────────────────────────────────────────────────────────────
  /// آخر تبويب نشط — يُحفظ فقط إذا كان NavigationConfig.persistLastTab = true
  static const String navLastTabIndex = 'nav_last_tab_index';

  // ── Sync module ────────────────────────────────────────────────────────────
  /// Epoch-ms timestamp when the sync lock was last acquired.
  /// Used by [SyncLock] to detect stale locks after app crashes.
  static const String syncLockAcquiredAt = 'sync_lock_acquired_at_ms';

  /// Epoch-ms timestamp of the last successful full delta-sync download.
  /// Used as the `updated_since` cursor on next sync.
  static const String syncLastDownloadAt = 'sync_last_download_at_ms';
}
