import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:app_template/presentation/feedback/app_feedback_service.dart';
import 'package:app_template/presentation/feedback/feedback_config.dart';
import 'package:app_template/presentation/feedback/feedback_style.dart';
import 'package:app_template/presentation/feedback/feedback_type.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/shared/widgets/misc/app_text.dart';
import 'motion_toast_adapter.dart';
import 'snackbar_adapter.dart';

/// [AppFeedbackService] adapter using FToast for a minimal bottom toast.
///
/// Shows a simple pill-shaped message with no icon or title.
/// Best for quick confirmations: "تم النسخ", "تم الحفظ".
class SimpleToastAdapter implements AppFeedbackService {
  AppFeedbackService _forStyle(FeedbackStyle style) => switch (style) {
        FeedbackStyle.motionToast => MotionToastAdapter(),
        FeedbackStyle.snackbar    => SnackbarAdapter(),
        FeedbackStyle.simpleToast => this,
      };
  @override
  void show(BuildContext context, FeedbackConfig config) {
    _showToast(
      context,
      message: config.message,
      seconds: config.duration?.inSeconds ?? 3,
      bgColor: config.type.accentColor(context),
      textColor: config.type.backgroundColor(context),
    );
  }

  @override
  void success(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.simpleToast) {
      _forStyle(style).success(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.success, message: message, title: title, duration: duration));
  }

  @override
  void error(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.simpleToast) {
      _forStyle(style).error(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.error, message: message, title: title, duration: duration));
  }

  @override
  void warning(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.simpleToast) {
      _forStyle(style).warning(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.warning, message: message, title: title, duration: duration));
  }

  @override
  void info(BuildContext context, String message,
      {String? title, Duration? duration, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.simpleToast) {
      _forStyle(style).info(context, message, title: title, duration: duration);
      return;
    }
    show(context, FeedbackConfig(type: FeedbackType.info, message: message, title: title, duration: duration));
  }

  @override
  void toast(BuildContext context, String message,
      {int seconds = 3, FeedbackStyle? style}) {
    if (style != null && style != FeedbackStyle.simpleToast) {
      _forStyle(style).toast(context, message, seconds: seconds);
      return;
    }
    _showToast(
      context,
      message: message,
      seconds: seconds,
      bgColor: context.colors.textPrimary,
      textColor: context.colors.textOnAccent,
    );
  }

  void _showToast(
    BuildContext context, {
    required String message,
    required int seconds,
    required Color bgColor,
    required Color textColor,
  }) {
    final fToast = FToast()..init(context);
    fToast.showToast(
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: seconds),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
        ),
        child: AppText(
          message,
          style: context.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
