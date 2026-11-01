import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';

/// Semantic type of a feedback message.
///
/// Used by adapters to pick the right color/icon/style automatically.
/// The caller never sets colors manually.
enum FeedbackType { success, error, warning, info }

extension FeedbackTypeX on FeedbackType {
  /// Default translated title — used when no custom title is supplied.
  String defaultTitle(BuildContext context) => switch (this) {
    FeedbackType.success => LocaleKeys.success.tr(),
    FeedbackType.error => LocaleKeys.error.tr(),
    FeedbackType.warning => LocaleKeys.warning.tr(),
    FeedbackType.info => LocaleKeys.info.tr(),
  };

  IconData get icon => switch (this) {
    FeedbackType.success => Icons.check_circle_rounded,
    FeedbackType.error => Icons.error_rounded,
    FeedbackType.warning => Icons.warning_rounded,
    FeedbackType.info => Icons.info_rounded,
  };

  /// Accent / brand color for the feedback type (border, icon tint).
  Color accentColor(BuildContext context) => switch (this) {
    FeedbackType.success => context.colors.feedbackSuccess,
    FeedbackType.error => context.colors.feedbackError,
    FeedbackType.warning => context.colors.feedbackWarning,
    FeedbackType.info => context.colors.feedbackInfo,
  };

  /// Card/background color — usually bgCard so toast blends with theme.
  Color backgroundColor(BuildContext context) => context.colors.bgCard;

  /// Primary text color.
  Color textColor(BuildContext context) => context.colors.textPrimary;
}
