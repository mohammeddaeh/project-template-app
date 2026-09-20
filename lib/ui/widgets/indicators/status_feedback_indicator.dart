import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/indicators/app_progress.dart';
import 'package:app_template/ui/widgets/misc/status_chip.dart';

/// أيقونة حالة دائرية — نبضة عند الانتقال إلى [StatusTone.success]، اهتزاز
/// عند الانتقال إلى [StatusTone.error]. [isLoading] يعرض مؤشر تحميل بصرف
/// النظر عن [tone].
///
/// يستهلك نفس ألوان [StatusChip] (`AppColors.status*`) — لا يخترع لوناً.
///
/// ```dart
/// StatusFeedbackIndicator(
///   tone: state.tone,          // StatusTone.success بعد نجاح إجراء
///   isLoading: state.isBusy,
/// )
/// ```
class StatusFeedbackIndicator extends StatefulWidget {
  const StatusFeedbackIndicator({
    super.key,
    this.tone = StatusTone.neutral,
    this.isLoading = false,
    this.size = 64,
  });

  final StatusTone tone;
  final bool isLoading;
  final double size;

  @override
  State<StatusFeedbackIndicator> createState() =>
      _StatusFeedbackIndicatorState();
}

class _StatusFeedbackIndicatorState extends State<StatusFeedbackIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );
  late StatusTone _lastTone = widget.tone;

  @override
  void didUpdateWidget(covariant StatusFeedbackIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tone != _lastTone) {
      // "تقليل الحركة" بالنظام — بلا نبضة ولا اهتزاز.
      final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) == true;
      if (!reduceMotion && widget.tone == StatusTone.success) {
        _pulseController.forward(from: 0);
      }
      if (!reduceMotion && widget.tone == StatusTone.error) {
        _shakeController.forward(from: 0);
      }
      _lastTone = widget.tone;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  (Color, Color) _colors(BuildContext context) {
    final colors = context.colors;
    return switch (widget.tone) {
      StatusTone.neutral => (colors.statusNeutralBg, colors.statusNeutralFg),
      StatusTone.info => (colors.statusInfoBg, colors.statusInfoFg),
      StatusTone.success => (colors.statusSuccessBg, colors.statusSuccessFg),
      StatusTone.warning => (colors.statusWarningBg, colors.statusWarningFg),
      StatusTone.error => (colors.statusErrorBg, colors.statusErrorFg),
    };
  }

  IconData get _icon => switch (widget.tone) {
    StatusTone.neutral => Icons.circle_outlined,
    StatusTone.info => Icons.info_outline_rounded,
    StatusTone.success => Icons.check_rounded,
    StatusTone.warning => Icons.warning_amber_rounded,
    StatusTone.error => Icons.close_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shakeController]),
      builder: (context, child) {
        final pulse = widget.tone == StatusTone.success
            ? 1 + (_pulseController.value * 0.12)
            : 1.0;
        final t = _shakeController.value;
        final shakeOffset = widget.tone == StatusTone.error
            ? math.sin(t * math.pi * 5) * 8 * (1 - t)
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(scale: pulse, child: child),
        );
      },
      child: AnimatedContainer(
        duration: AppMotion.base,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Center(
          child: widget.isLoading
              ? AppProgress.circular(
                  color: foreground,
                  dimension: widget.size * 0.4,
                  strokeWidth: 2.5,
                )
              : AnimatedSwitcher(
                  duration: AppMotion.base,
                  switchInCurve: AppMotion.emphasizedCurve,
                  switchOutCurve: AppMotion.fastCurve,
                  child: Icon(
                    _icon,
                    key: ValueKey<StatusTone>(widget.tone),
                    color: foreground,
                    size: widget.size * 0.42,
                  ),
                ),
        ),
      ),
    );
  }
}
