import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/crash_reporting/adapters/crashlytics_log_delegate.dart';

/// Entry point for the crash-reporting module.
///
/// ## What this does
/// 1. Enables Crashlytics collection.
/// 2. Routes all **Flutter framework errors** (`FlutterError.onError`) to
///    Crashlytics as non-fatal errors.
/// 3. Catches all **async / platform errors** (`PlatformDispatcher.onError`)
///    and records them as fatal errors.
/// 4. Replaces [LogService]'s delegate with [CrashlyticsLogDelegate] so that
///    every `LogService.error(...)` call is forwarded automatically —
///    **no changes needed in any Feature or Cubit**.
///
/// ## Setup
/// See `SETUP.md` in this folder.
///
/// ## Usage
/// ```dart
/// // main.dart — after Firebase.initializeApp()
/// await CrashReportingModule.initialize();
/// ```
/// After that, use [LogService] as usual — Crashlytics receives everything.
///
/// ### Setting user identity (after login)
/// ```dart
/// CrashReportingModule.setUserId('user_123');
/// CrashReportingModule.setUserAttribute('role', 'admin');
/// ```
///
/// ### Clearing user identity (on logout)
/// ```dart
/// CrashReportingModule.clearUser();
/// ```
abstract final class CrashReportingModule {
  static bool _initialized = false;

  /// Initialises Crashlytics and wires it into [LogService].
  ///
  /// Must be called **after** `Firebase.initializeApp()`.
  /// Safe to call multiple times — subsequent calls are no-ops.
  ///
  /// [enabled] — pass `false` in debug mode to suppress Crashlytics uploads
  /// while still logging to console via the default delegate.
  static Future<void> initialize({bool enabled = true}) async {
    if (_initialized) return;

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);

    if (enabled) {
      // Flutter framework errors → Crashlytics (non-fatal)
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Async / zone / platform errors → Crashlytics (fatal)
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // All LogService.error() calls now go to Crashlytics automatically
      LogService.setDelegate(const CrashlyticsLogDelegate());
    }

    _initialized = true;
    LogService.info(
      'CrashReportingModule initialized (enabled=$enabled)',
      tag: 'CRASH',
    );
  }

  // ── User identity ──────────────────────────────────────────────────────────

  /// Sets the user ID attached to every Crashlytics report.
  /// Call after a successful login.
  static Future<void> setUserId(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Attaches a custom key-value pair to every report (max 64 keys).
  /// Useful for role, subscription tier, device config, etc.
  static Future<void> setUserAttribute(String key, String value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Clears user identity — call on logout.
  static Future<void> clearUser() async {
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  // ── Manual reporting ───────────────────────────────────────────────────────

  /// Records a non-fatal error directly (e.g. caught but worth tracking).
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }
}
