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

  /// طباعة الرؤوس والأجسام لكل طلب ناجح أيضاً (debug فقط).
  ///
  /// **اتركه `false`.** السجل الكامل لكل طلب هو بالضبط ما يُخفي الأخطاء: بمشروع
  /// حقيقي بُني على هذا القالب ظلّ خطأَا `401` يُطبعان بكل إقلاع **لأشهر** وسط
  /// مئات الأسطر — الإشارة كانت موجودة وغير مقروءة. الوضع الافتراضي (سطر لكل
  /// نجاح، وكل شيء عند الفشل) يجعل الخطأ مرئياً بلا بحث. فعّله لجلسة تصحيح
  /// واحدة عند الحاجة، ثم أعده.
  static const verboseNetworkLog = false;

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

  /// Enable the generic import/export module.
  ///
  /// **When true**: `DataTransferSheet.show(context, resource: '<name>')` works
  /// from anywhere for any resource the backend declares under
  /// `GET /api/v1/data-transfer/resources` — export to CSV/Excel with a column
  /// picker, download an import template, and import in two phases (review the
  /// row-by-row errors, then confirm).
  ///
  /// The screens carry **no per-feature code**. A feature becomes transferable
  /// by declaring a `*.transfer.ts` server-side; nothing is added, built or
  /// shipped here. That is the whole point of the module, and the reason it is
  /// one flag rather than one flag per feature.
  ///
  /// **When false**: `DataTransferPlugin.initialize()` returns immediately,
  /// nothing is registered, and `DataTransferSheet.show` refuses instead of
  /// opening a screen whose dependencies are absent — the entry point cannot
  /// appear without the module behind it.
  ///
  /// ⚠️ Requires the backend half (`backend_template/src/core/data-transfer/`).
  /// With an older server every call answers 404 and the sheet shows an error
  /// where a resource list should be.
  static const dataTransfer = false;

  /// Enable the devices & sessions module.
  ///
  /// **When true**: a "Devices & sessions" entry appears in Settings, showing
  /// where this account is signed in and letting the user end any of those
  /// sessions. Sign-in requests are also labelled (`device_info`) so the list
  /// reads "Samsung SM-G991B · android · v1.2.0" rather than "unknown device".
  ///
  /// **When false**: `MultiDevicePlugin.initialize()` returns immediately and
  /// `DevicesSection` renders nothing — zero overhead, no dead route. Both
  /// checks read this same flag, so the tile can never appear without the
  /// dependencies behind it.
  ///
  /// ⚠️ **The trade-off of leaving it off**: there is then no way, from inside
  /// the app, to end the session of a lost or stolen device. Changing the
  /// password still ends every session — that becomes the only route.
  ///
  /// The server side (`GET`/`DELETE /api/v1/auth/sessions`) is available
  /// regardless of this flag; it is infrastructure, not a feature. This flag
  /// governs the client only.
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


