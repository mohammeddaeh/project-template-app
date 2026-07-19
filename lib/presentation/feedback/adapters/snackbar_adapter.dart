import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/presentation/feedback/app_feedback_service.dart';
import 'package:app_template/presentation/feedback/feedback_config.dart';
import 'package:app_template/presentation/feedback/feedback_style.dart';
import 'package:app_template/presentation/feedback/feedback_type.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'motion_toast_adapter.dart';
import 'simple_toast_adapter.dart';

/// [AppFeedbackService] adapter backed by Material [SnackBar].
///
/// Best for messages that need an action button (retry, undo, dismiss).
/// Falls back to a dismiss button when no action is provided.
class SnackbarAdapter implements AppFeedbackService {
  AppFeedbackService _forStyle(FeedbackStyle style) => switch (style) {
        FeedbackStyle.motionToast => MotionToastAdapter(),
        FeedbackStyle.snackbar    => this,
        FeedbackStyle.simpleToast => SimpleToastAdapter(),
      };
  static const _defaultDuration = Duration(seconds: 4);

  @override
  void show(BuildContext context, FeedbackConfig config) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final accentColor = config.type.accentColor(context);

    messenger.showSnackBar(
      SnackBar(
        duration:  config.duration ?? _defaultDuration,
        behavior:  SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
        content: Row(
          children: [
            Icon(config.type.icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (config.title != null)
                    Text(
                      config.title!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: config.type.textColor(context),
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    config.message,
                    style: TextStyle(
                      color: config.type.textColor(context).withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: config.action != null
            ? SnackBarAction(
                label:     config.action!.label,
                textColor: accentColor,
                onPressed: config.action!.onTap,
              )
            : SnackBarAction(
                label:     LocaleKeys.dismiss.tr(),
                textColor: context.colors.secondary,
                onPressed: () => messenger.hideCurrentSnackBar(),
              ),
      ),
    );
  }

  @override
  void success(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.snackbar) {
      _forStyle(style).success(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.success, message: message, title: title, duration: duration));
  }

  @override
  void error(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.snackbar) {
      _forStyle(style).error(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.error, message: message, title: title, duration: duration));
  }

  @override
  void warning(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.snackbar) {
      _forStyle(style).warning(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.warning, message: message, title: title, duration: duration));
  }

  @override
  void info(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.snackbar) {
      _forStyle(style).info(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.info, message: message, title: title, duration: duration));
  }

  @override
  void toast(BuildContext context, String message,
      {int seconds = 3, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.snackbar) {
      _forStyle(style).toast(context, message, seconds: seconds);
      return;
    }
    show(context, FeedbackConfig(
      type: FeedbackType.info,
      message: message,
      duration: Duration(seconds: seconds),
    ));
  }
}
