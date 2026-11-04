import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/app_motion.dart';

/// يصغّر [child] أثناء الضغط — رد فعل لمسي عام لأي عنصر قابل للنقر.
///
/// يراقب الضغط بـ[Listener] لا [GestureDetector]: لا يدخل ساحة الإيماءة، فلا
/// يتنازع مع `InkWell`/`GestureDetector` الخاص بالابن على التقاط اللمسة —
/// يُغلَّف حولهما بلا تعديل سلوك النقر نفسه.
///
/// **بنابضَين**: يصغر بـ[AppMotion.springSnappy] ويرجع بـ[AppMotion.springGentle]
/// بارتدادٍ خفيف — وإفلاتٌ قبل أن يكتمل الضغط ينعطف من موضعه ولا يقفز.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.scale = AppMotion.pressedScale,
  });

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  // In initState, not a lazy `late` initializer: under reduced motion nothing
  // reads it, and dispose() would then create it on a deactivated element.
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  void _setPressed(bool pressed) => pressed
      ? _scale.springTo(widget.scale, AppMotion.springSnappy)
      : _scale.springTo(1, AppMotion.springGentle);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // "تقليل الحركة" بالنظام — بلا تصغير، الابن كما هو.
    if (AppMotion.of(context).isReduced) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
