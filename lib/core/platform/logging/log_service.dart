import 'dart:developer' as dev;

import 'package:app_template/core/platform/config/app_settings.dart';

/// Static logging utility — call anywhere without DI.
///
/// Controlled by [AppSettings.enableLogging] (disabled in release builds).
///
/// ```dart
/// LogService.info('User logged in', tag: 'AuthCubit');
/// LogService.error('Request failed', error: e, stackTrace: st);
/// ```
///
/// To swap the logging backend (e.g. to Firebase Crashlytics in release),
/// override [LogService._delegate] with your own [LogDelegate] instance.
abstract final class LogService {
  LogService._();

  static LogDelegate _delegate = const _DeveloperLogDelegate();

  /// Override at app startup to change the logging backend.
  /// ```dart
  /// LogService.setDelegate(CrashlyticsLogDelegate());
  /// ```
  static void setDelegate(LogDelegate delegate) => _delegate = delegate;

  static void info(String message, {String? tag}) =>
      _delegate.info(message, tag: tag);

  static void warning(String message, {String? tag}) =>
      _delegate.warning(message, tag: tag);

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _delegate.error(message, tag: tag, error: error, stackTrace: stackTrace);

  static void debug(String message, {String? tag}) =>
      _delegate.debug(message, tag: tag);
}

// ── Delegate interface ────────────────────────────────────────────────────────

/// Implement this to redirect logs to any backend (console, Crashlytics, etc.).
abstract interface class LogDelegate {
  void info(String message, {String? tag});
  void warning(String message, {String? tag});
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace});
  void debug(String message, {String? tag});
}

// ── Default: dart:developer ───────────────────────────────────────────────────

class _DeveloperLogDelegate implements LogDelegate {
  const _DeveloperLogDelegate();

  static const _reset   = '\u001b[0m';
  static const _cyan    = '\u001b[36m';
  static const _yellow  = '\u001b[33m';
  static const _red     = '\u001b[31m';
  static const _magenta = '\u001b[35m';

  static String _c(String msg, String color) => '$color$msg$_reset';

  @override
  void info(String message, {String? tag}) {
    if (!AppSettings.enableLogging) return;
    dev.log(_c(message, _cyan), name: tag ?? 'INFO');
  }

  @override
  void warning(String message, {String? tag}) {
    if (!AppSettings.enableLogging) return;
    dev.log(_c('⚠️  $message', _yellow), name: tag ?? 'WARN');
  }

  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!AppSettings.enableLogging) return;
    dev.log(
      _c('❌  $message', _red),
      name: tag ?? 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void debug(String message, {String? tag}) {
    if (!AppSettings.enableLogging) return;
    dev.log(_c('🐛  $message', _magenta), name: tag ?? 'DEBUG');
  }
}
