import 'package:app_template/core/platform/permissions/app_permission.dart';

/// Central feature activation file.
///
/// ─── HOW TO USE ──────────────────────────────────────────────────────────────
/// 1. Set the feature flag to `true` or `false` below.
/// 2. Run:  dart run scripts/sync_permissions.dart
///    → AndroidManifest.xml and Info.plist are updated automatically.
/// 3. Use the feature in your code — PermissionsService guards calls
///    automatically based on these flags.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppFeatures {
  // ── Debug / Development ────────────────────────────────────────────────────
  /// تخطي تسجيل الدخول مباشرةً إلى Template Showcase.
  /// اضبطه على false قبل إصدار أي build للإنتاج.
  static const debugSkipLogin = true;

  // ── Platform permissions ───────────────────────────────────────────────────
  static const camera            = false;
  static const microphone        = false;
  static const location          = false;
  static const locationAlways    = false;
  static const photos            = false;
  static const fileStorage       = false;
  static const contacts          = false;
  static const bluetooth         = false;
  static const pushNotifications = false;

  // ── Optional modules ──────────────────────────────────────────────────────
  /// Enable local (on-device) notifications — reminders, alarms, etc.
  /// Run `dart run scripts/sync_permissions.dart` after changing this.
  static const localNotifications = false;

  // ── Optional modules ──────────────────────────────────────────────────────
  /// Enable offline-first sync engine.
  /// When false: SyncSDK.initialize() exits immediately — zero overhead.
  /// When true: run `dart run build_runner build` after adding feature contracts.
  static const offlineSync = false;

  /// Enable multi-device session management.
  /// When false: MultiDevicePlugin.initialize() exits immediately — zero overhead.
  /// When true: login requests are enriched with device context automatically.
  static const multiDevice = false;

  // ── Firebase-backed modules ───────────────────────────────────────────────
  // All require google-services.json (Android) / GoogleService-Info.plist (iOS).
  // ModulesBootstrap calls Firebase.initializeApp() once when any are enabled.

  /// Enable Firebase Crashlytics crash reporting (wired into LogService).
  static const crashReporting = false;

  /// Enable Firebase Analytics event tracking.
  static const analytics = false;

  /// Enable Firebase Remote Config feature flags / remote values.
  static const remoteConfig = false;

  // ── Optional platform services ────────────────────────────────────────────
  // Set to `true` to register the service in DI automatically.
  // Set to `false` → service is NOT registered → getIt<X>() will throw if called.
  // Each service only adds its package overhead when enabled.

  /// Fingerprint / Face ID authentication via `local_auth`.
  static const biometrics = false;

  /// System clipboard (copy / paste) — Flutter built-in, very lightweight.
  static const clipboard = true;

  /// System share sheet (text / URL / file) via `share_plus`.
  static const shareSheet = false;

  /// File pick / download / open / save via `file_picker` + `open_filex`.
  static const fileOperations = false;

  /// App foreground/background lifecycle stream — Flutter built-in.
  static const appLifecycle = true;

  /// Haptic feedback on user interactions — uses Flutter's built-in HapticFeedback.
  /// When true: context.feedback.* automatically triggers matching haptics.
  /// When false: zero overhead — service not registered, no HapticFeedback calls.
  static const haptics = true;

  /// Certificate pinning — only for apps with strict security requirements.
  /// When enabled, set fingerprints in `CertificatePinningConfig`.
  static const certificatePinning = false;

  // ── Runtime guard ─────────────────────────────────────────────────────────
  /// Returns `false` if the feature is disabled — PermissionsService
  /// will return [AppPermissionStatus.denied] without prompting the user.
  static bool isEnabled(AppPermission permission) => switch (permission) {
        AppPermission.camera         => camera,
        AppPermission.microphone     => microphone,
        AppPermission.location       => location,
        AppPermission.locationAlways => locationAlways,
        AppPermission.photos         => photos,
        AppPermission.storage        => fileStorage,
        AppPermission.notifications  => pushNotifications,
        AppPermission.contacts       => contacts,
        AppPermission.bluetooth      => bluetooth,
      };
}


