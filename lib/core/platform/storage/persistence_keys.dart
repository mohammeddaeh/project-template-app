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

  // ── Current-user cache (CurrentUserRepository) ─────────────────────────────
  // The token itself stays in SecureStorage ([token] above); these hold the
  // NON-sensitive snapshot restored at startup, so identity and permissions
  // survive a restart instead of resetting to empty on every launch.
  //
  // Without them the app holds a valid token and does not know whose it is
  // until `GET /users/me` returns — a window in which every permission check
  // answers "no", so the user briefly sees a version of the app with their own
  // controls missing, then watches them appear.

  /// JSON-encoded `AuthUser` snapshot — written on login and after every
  /// successful `GET /account/me` refresh.
  ///
  /// A bridge across app restarts, never the source of truth: `SplashCubit`
  /// restores it so the first frame after a cached token is not empty, and
  /// `SessionSyncService` overwrites it from the server moments later.
  ///
  /// `cached_permission_keys` and `cached_is_super_admin` were removed
  /// alongside it — they persisted two fields no endpoint ever sent.
  static const String cachedCurrentUser = 'cached_current_user';
}
