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
  /// successful `GET /users/me` refresh.
  static const String cachedCurrentUser = 'cached_current_user';

  /// JSON-encoded `List<String>` of the cached user's effective permission
  /// keys — kept in sync with [cachedCurrentUser] at all times. Two stores that
  /// can disagree are worse than one that is briefly empty.
  static const String cachedPermissionKeys = 'cached_permission_keys';

  /// Whether the cached session holds an unrestricted (super-admin) role.
  /// Persisted beside the two above because it is part of the same snapshot:
  /// restoring the user without it leaves an admin missing their own controls
  /// until the background refresh returns.
  static const String cachedIsSuperAdmin = 'cached_is_super_admin';
}
