import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// [LogDelegate] that forwards every log call to Firebase Crashlytics.
///
/// - [error] → `FirebaseCrashlytics.instance.recordError` (fatal = false)
/// - [warning] / [info] / [debug] → `FirebaseCrashlytics.instance.log`
///   (appear in the "Logs" tab of each crash report)
///
/// Set via [LogService.setDelegate] — never construct directly.
/// Use [CrashReportingModule.initialize] which handles this automatically.
class CrashlyticsLogDelegate implements LogDelegate {
  const CrashlyticsLogDelegate();

  @override
  void info(String message, {String? tag}) {
    _log('INFO', tag, message);
  }

  @override
  void warning(String message, {String? tag}) {
    _log('WARN', tag, message);
  }

  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', tag, message);
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: '[$tag] $message',
        fatal: false,
      );
    }
  }

  @override
  void debug(String message, {String? tag}) {
    _log('DEBUG', tag, message);
  }

  static void _log(String level, String? tag, String message) {
    FirebaseCrashlytics.instance.log('[$level][${tag ?? '?'}] $message');
  }
}
