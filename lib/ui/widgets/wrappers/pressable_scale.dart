import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/app_motion.dart';

/// يصغّر [child] أثناء الضغط — رد فعل لمسي عام لأي عنصر قابل للنقر.
///
/// يراقب الضغط بـ[Listener] لا [GestureDetector]: لا يدخل ساحة الإيماءة، فلا
/// يتنازع مع `InkWell`/`GestureDetector` الخاص بالابن على التقاط اللمسة —
/// يُغلَّف حولهما بلا تعديل سلوك النقر نفسه.
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

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // "تقليل الحركة" بالنظام — بلا تصغير، الابن كما هو.
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.fastCurve,
        child: widget.child,
      ),
    );
  }
}
