import 'package:flutter/material.dart';

import 'feedback_config.dart';
import 'feedback_style.dart';
import 'feedback_type.dart';

/// Abstract contract for in-app feedback (toasts, snackbars, banners).
///
/// ─── Adapters ────────────────────────────────────────────────────────────────
/// • [adapters/motion_toast_adapter.dart]  — styled toast  (default)
/// • [adapters/snackbar_adapter.dart]      — Material SnackBar (with action)
/// • [adapters/simple_toast_adapter.dart]  — bottom toast (minimal)
///
/// ─── How to swap default adapter ─────────────────────────────────────────────
/// In injection_module.dart change one line:
///   `MotionToastAdapter()` → `SnackbarAdapter()`
/// No other code needs to change.
///
/// ─── Per-call style override ─────────────────────────────────────────────────
/// Pass [FeedbackStyle] to any convenience method to override the adapter for
/// that single call without changing the registered default:
///
/// ```dart
/// context.feedback.success(LocaleKeys.saved.tr());
/// context.feedback.error(LocaleKeys.noInternetConnection.tr());
/// context.feedback.toast('تم النسخ');
///
/// // تجاوز الـ adapter لهذه الرسالة فقط:
/// context.feedback.error('فشل الاتصال', style: FeedbackStyle.snackbar);
///
/// // Full config (e.g. with action):
/// context.feedback.show(context, FeedbackConfig(
///   type: FeedbackType.error,
///   message: LocaleKeys.noInternetConnection.tr(),
///   action: FeedbackAction(label: 'إعادة', onTap: _retry),
/// ));
/// ```
abstract interface class AppFeedbackService {
  /// Show a fully configured feedback message.
  void show(BuildContext context, FeedbackConfig config);

  /// Convenience — shows a [FeedbackType.success] toast.
  void success(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style});

  /// Convenience — shows a [FeedbackType.error] toast.
  void error(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style});

  /// Convenience — shows a [FeedbackType.warning] toast.
  void warning(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style});

  /// Convenience — shows a [FeedbackType.info] toast.
  void info(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style});

  /// Shows a minimal bottom toast — no icon, no title, plain message.
  void toast(BuildContext context, String message,
      {int seconds = 3, FeedbackStyle? style});
}
