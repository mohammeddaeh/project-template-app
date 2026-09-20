import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/app_elevation.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Coach-mark عام — يظلّل الشاشة ويترك فتحةً حول العنصر المُشار إليه
/// بـ[targetKey]، مع فقاعة شرح بجانبه.
///
/// ```dart
/// final addButtonKey = GlobalKey();
///
/// IconButton(key: addButtonKey, onPressed: ..., icon: Icon(Icons.add));
///
/// // عند لحظة التعريف (أول تشغيل مثلاً):
/// GuideOverlay.show(
///   context,
///   targetKey: addButtonKey,
///   title: LocaleKeys.guideAddTitle.tr(),
///   message: LocaleKeys.guideAddMessage.tr(),
///   actionLabel: LocaleKeys.guideGotIt.tr(),
/// );
/// ```
///
/// العنصر المُشار إليه يجب أن يكون **مبنيّاً فعلاً** حين يُستدعى [show] —
/// الفتحة تُحسب من `RenderBox` حالي، لا موضعٍ مفترض.
class GuideOverlay {
  GuideOverlay._();

  /// يُظهر الـoverlay ويُنهي الـ`Future` عند إغلاقه (نقرة خارج الفقاعة أو زر
  /// الإجراء).
  static Future<void> show(
    BuildContext context, {
    required GlobalKey targetKey,
    required String title,
    required String message,
    required String actionLabel,
    double holePadding = 8,
    double holeRadius = 12,
  }) {
    final overlayState = Overlay.of(context);
    final completer = Completer<void>();
    late final OverlayEntry entry;

    void dismiss() {
      entry.remove();
      if (!completer.isCompleted) completer.complete();
    }

    entry = OverlayEntry(
      builder: (_) => _GuideOverlayContent(
        targetKey: targetKey,
        title: title,
        message: message,
        actionLabel: actionLabel,
        holePadding: holePadding,
        holeRadius: holeRadius,
        onDismiss: dismiss,
      ),
    );

    overlayState.insert(entry);
    return completer.future;
  }
}

class _GuideOverlayContent extends StatefulWidget {
  const _GuideOverlayContent({
    required this.targetKey,
    required this.title,
    required this.message,
    required this.onDismiss,
    required this.holePadding,
    required this.holeRadius,
    required this.actionLabel,
  });

  final GlobalKey targetKey;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onDismiss;
  final double holePadding;
  final double holeRadius;

  @override
  State<_GuideOverlayContent> createState() => _GuideOverlayContentState();
}

class _GuideOverlayContentState extends State<_GuideOverlayContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );

  @override
  void initState() {
    super.initState();
    // "تقليل الحركة" بالنظام — تظهر الفقاعة كاملةً فوراً بلا دخولٍ متحرّك.
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  // بلا `ancestor` عمداً: يُحسَب أثناء بناء محتوى الـoverlay نفسه، الذي لا
  // يملك بعدُ `RenderObject` بأوّل إطار (يُنشأ بعد اكتمال هذا الـbuild). ولأنّ
  // الـOverlay يملأ الشاشة من `(0,0)` دائماً، الإحداثيات **الشاملة** مطابقةٌ
  // لإحداثياته المحلّية — فلا حاجة أصلاً لأصلٍ نسبيّ.
  Rect? _targetRect() {
    final renderBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return null;
    }
    final topLeft = renderBox.localToGlobal(Offset.zero);
    return topLeft & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _targetRect();
    final screenSize = MediaQuery.sizeOf(context);

    // العنصر غير موجودٍ بالشجرة حالياً — لا يُظلَّل شيء، الفقاعةُ فقط تُغلَق.
    if (targetRect == null) {
      return const SizedBox.shrink();
    }

    final hole = targetRect.inflate(widget.holePadding);
    final spaceBelow = screenSize.height - hole.bottom;
    final bubbleBelow = spaceBelow > 160 || hole.top < 160;

    return FadeTransition(
      opacity: _entrance,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: CustomPaint(
              size: screenSize,
              painter: _SpotlightPainter(
                hole: hole,
                holeRadius: widget.holeRadius,
                color: context.colors.scrim.withValues(alpha: 0.72),
              ),
            ),
          ),
          _Bubble(
            title: widget.title,
            message: widget.message,
            actionLabel: widget.actionLabel,
            onDismiss: widget.onDismiss,
            entrance: _entrance,
            top: bubbleBelow ? hole.bottom + 16 : null,
            bottom: bubbleBelow ? null : screenSize.height - hole.top + 16,
            screenWidth: screenSize.width,
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.holeRadius,
    required this.color,
  });

  final Rect hole;
  final double holeRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(holeRadius)));
    final overlay = Path.combine(PathOperation.difference, full, cutout);
    canvas.drawPath(overlay, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.holeRadius != holeRadius ||
      oldDelegate.color != color;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.title,
    required this.message,
    required this.onDismiss,
    required this.entrance,
    required this.screenWidth,
    required this.actionLabel,
    this.top,
    this.bottom,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onDismiss;
  final Animation<double> entrance;
  final double screenWidth;
  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: 20,
      right: 20,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: entrance,
          curve: AppMotion.emphasizedCurve,
        ),
        alignment: top != null ? Alignment.topCenter : Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth - 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.bgElevated,
            borderRadius: AppRadius.mdRadius,
            boxShadow: AppElevation.lg(context.colors.shadowColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
