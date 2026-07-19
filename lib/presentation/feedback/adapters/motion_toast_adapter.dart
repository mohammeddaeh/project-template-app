import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';

import 'package:app_template/presentation/feedback/app_feedback_service.dart';
import 'package:app_template/presentation/feedback/feedback_config.dart';
import 'package:app_template/presentation/feedback/feedback_style.dart';
import 'package:app_template/presentation/feedback/feedback_type.dart';
import 'snackbar_adapter.dart';
import 'simple_toast_adapter.dart';

/// [AppFeedbackService] adapter backed by motion_toast.
///
/// Shows a styled toast sliding in from the top with icon, title, and message.
/// To swap: replace this with another adapter in injection_module.dart.
class MotionToastAdapter implements AppFeedbackService {
  static const _defaultDuration = Duration(seconds: 3);

  AppFeedbackService _forStyle(FeedbackStyle style) => switch (style) {
        FeedbackStyle.motionToast => this,
        FeedbackStyle.snackbar    => SnackbarAdapter(),
        FeedbackStyle.simpleToast => SimpleToastAdapter(),
      };

  @override
  void show(BuildContext context, FeedbackConfig config) {
    final type     = config.type;
    final duration = config.duration ?? _defaultDuration;
    final title    = config.title ?? type.defaultTitle(context);

    MotionToast(
      toastDuration:  duration,
      icon:           type.icon,
      primaryColor:   type.backgroundColor(context),
      secondaryColor: type.accentColor(context),
      title: Text(
        title,
        style: TextStyle(
          color:      type.textColor(context),
          fontSize:   16,
          fontWeight: FontWeight.w600,
        ),
      ),
      description: Text(
        config.message,
        maxLines: 2,
        style: TextStyle(
          color:      type.textColor(context).withValues(alpha: 0.9),
          fontSize:   14,
          fontWeight: FontWeight.w500,
        ),
      ),
      width:          342,
      height:         85,
      barrierColor:   type.accentColor(context).withValues(alpha: 0.16),
      animationType:  AnimationType.slideInFromTop,
      toastAlignment: Alignment.topCenter,
      displayBorder:  true,
    ).show(context);
  }

  @override
  void success(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.motionToast) {
      _forStyle(style).success(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.success, message: message, title: title, duration: duration));
  }

  @override
  void error(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.motionToast) {
      _forStyle(style).error(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.error, message: message, title: title, duration: duration));
  }

  @override
  void warning(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.motionToast) {
      _forStyle(style).warning(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.warning, message: message, title: title, duration: duration));
  }

  @override
  void info(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.motionToast) {
      _forStyle(style).info(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.info, message: message, title: title, duration: duration));
  }

  @override
  void toast(BuildContext context, String message, {int seconds = 3, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.motionToast) {
      _forStyle(style).toast(context, message, seconds: seconds);
      return;
    }
    // motion_toast doesn't have a minimal mode — delegate to a bottom description-only toast
    MotionToast(
      toastDuration:  Duration(seconds: seconds),
      icon:           Icons.info_outline_rounded,
      primaryColor:   Theme.of(context).colorScheme.surface,
      secondaryColor: Theme.of(context).colorScheme.outline,
      title:          const SizedBox.shrink(),
      description: Text(
        message,
        style: TextStyle(
          color:      Theme.of(context).colorScheme.onSurface,
          fontSize:   14,
          fontWeight: FontWeight.w400,
        ),
      ),
      width:          300,
      height:         60,
      animationType:  AnimationType.slideInFromBottom,
      toastAlignment: Alignment.bottomCenter,
    ).show(context);
  }
}
