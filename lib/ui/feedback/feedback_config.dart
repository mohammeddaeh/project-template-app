import 'package:flutter/material.dart';

import 'feedback_type.dart';

/// Optional action button shown in snackbar-style feedback.
class FeedbackAction {
  const FeedbackAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// All data needed to display a feedback message.
///
/// ─── Usage ───────────────────────────────────────────────────────────────────
/// ```dart
/// // Simple — use context.feedback shortcuts instead
/// context.feedback.success(LocaleKeys.saved.tr());
///
/// // Full config — for snackbar with action
/// context.feedback.show(FeedbackConfig(
///   type: FeedbackType.error,
///   message: LocaleKeys.noInternetConnection.tr(),
///   action: FeedbackAction(label: LocaleKeys.retry.tr(), onTap: _retry),
/// ));
/// ```
class FeedbackConfig {
  const FeedbackConfig({
    required this.type,
    required this.message,
    this.title,
    this.duration,
    this.action,
  });

  final FeedbackType type;

  /// Already-translated message string.
  final String message;

  /// Already-translated title. If null the adapter uses [FeedbackType.defaultTitle].
  final String? title;

  final Duration? duration;

  /// Optional action — only used by adapters that support it (e.g. SnackbarAdapter).
  final FeedbackAction? action;
}
