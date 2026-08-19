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

  // `syncLastDownloadAt` was here, described as "the `updated_since` cursor for
  // the next sync", and read by **nothing** for its entire life — because no
  // pull path existed to read it.
  //
  // It moved to `sync_meta` (`modules/sync/data/sync_cursor_store.dart`) when
  // one was built, for three reasons. A module writing into `core/` is the
  // dependency direction this template forbids, and it is how a deleted module
  // leaves orphans in the heart of the app. The table it belongs in had been
  // shipped since schema v1 with no reader. And a single global key could never
  // be what a cursor has to be: **one per entity** — with one shared cursor, an
  // entity whose pull failed still has the cursor advanced by whichever entity
  // succeeded after it, and everything it missed in that window is skipped
  // forever.

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

  // ── Access-control module (AbilitiesStore) ────────────────────────────────
  /// JSON-encoded `AbilitySet` — written after every successful
  /// `GET /authz/me`, restored before the first frame.
  ///
  /// Same role as [cachedCurrentUser] and for the same reason, applied to the
  /// other half of the problem: without it a relaunch with a valid token starts
  /// with **every gate shut**, and the user watches their own controls appear a
  /// moment later. Cleared on sign-out — the set belongs to an account, not to
  /// a device.
  static const String cachedAbilities = 'cached_abilities';
}
