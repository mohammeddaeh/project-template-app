import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_template/core/platform/haptics/haptic_service.dart';
import 'package:get_it/get_it.dart';

import 'app_feedback_service.dart';
import 'feedback_config.dart';
import 'feedback_style.dart';
import 'feedback_type.dart';

/// Ergonomic proxy that binds [BuildContext] so callers never pass it manually.
///
/// ─── Usage ───────────────────────────────────────────────────────────────────
/// ```dart
/// context.feedback.success(LocaleKeys.saved.tr());
/// context.feedback.error(LocaleKeys.noInternetConnection.tr());
/// context.feedback.warning(LocaleKeys.weakConnection.tr());
/// context.feedback.info(LocaleKeys.syncInProgress.tr());
/// context.feedback.toast('تم النسخ');
///
/// // Full config with action button:
/// context.feedback.show(FeedbackConfig(
///   type: FeedbackType.error,
///   message: LocaleKeys.noInternetConnection.tr(),
///   action: FeedbackAction(label: LocaleKeys.retry.tr(), onTap: _retry),
/// ));
/// ```
extension FeedbackContextExtension on BuildContext {
  /// Returns a context-bound proxy — no need to pass [BuildContext] manually.
  BoundFeedback get feedback => BoundFeedback(this);
}

/// Context-bound wrapper around [AppFeedbackService].
///
/// The [BuildContext] is captured once; all calls forward to the registered adapter.
/// Obtain via `context.feedback` — never construct directly.
///
/// When [AppFeatures.haptics] is enabled, each call automatically triggers
/// the matching haptic intensity — no extra code needed in the UI layer:
/// - success / warning / info → [HapticService.medium] / [HapticService.medium] / [HapticService.light]
/// - error → [HapticService.heavy]
/// - toast → [HapticService.selection]
class BoundFeedback {
  const BoundFeedback(this._context);

  final BuildContext _context;

  AppFeedbackService get _service => GetIt.I<AppFeedbackService>();

  // Null when AppFeatures.haptics = false (service not registered → zero overhead).
  HapticService? get _haptics =>
      GetIt.I.isRegistered<HapticService>() ? GetIt.I<HapticService>() : null;

  // ── Throttle ─────────────────────────────────────────────────────────────────
  // نفس الرسالة محجوبة طوال فترة عرضها — Timer يمتد بمدة الـ toast.
  // رسالة مختلفة تُعرض فوراً بغض النظر عن الرسالة السابقة.
  // static → مشترك عبر كل BoundFeedback instances في التطبيق.
  static String? _activeMessage;
  static Timer? _cooldownTimer;

  bool _throttled(String message, {Duration cooldown = const Duration(seconds: 3)}) {
    if (_activeMessage == message && (_cooldownTimer?.isActive ?? false)) return true;
    _cooldownTimer?.cancel();
    _activeMessage = message;
    _cooldownTimer = Timer(cooldown, () => _activeMessage = null);
    return false;
  }

  void show(FeedbackConfig config) {
    final cooldown = config.duration ?? const Duration(seconds: 3);
    if (_throttled(config.message, cooldown: cooldown)) return;
    switch (config.type) {
      case FeedbackType.success: _haptics?.medium();
      case FeedbackType.error:   _haptics?.heavy();
      case FeedbackType.warning: _haptics?.medium();
      case FeedbackType.info:    _haptics?.light();
    }
    _service.show(_context, config);
  }

  void success(String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (_throttled(message, cooldown: duration ?? const Duration(seconds: 3))) return;
    _haptics?.medium();
    _service.success(_context, message,
        title: title, duration: duration, style: style);
  }

  void error(String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (_throttled(message, cooldown: duration ?? const Duration(seconds: 3))) return;
    _haptics?.heavy();
    _service.error(_context, message,
        title: title, duration: duration, style: style);
  }

  void warning(String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (_throttled(message, cooldown: duration ?? const Duration(seconds: 3))) return;
    _haptics?.medium();
    _service.warning(_context, message,
        title: title, duration: duration, style: style);
  }

  void info(String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (_throttled(message, cooldown: duration ?? const Duration(seconds: 3))) return;
    _haptics?.light();
    _service.info(_context, message,
        title: title, duration: duration, style: style);
  }

  void toast(String message, {int seconds = 3, FeedbackStyle? style}) {
    if (_throttled(message, cooldown: Duration(seconds: seconds))) return;
    _haptics?.selection();
    _service.toast(_context, message, seconds: seconds, style: style);
  }
}
