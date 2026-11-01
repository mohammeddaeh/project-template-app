import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/app_motion.dart';

/// **هزّةٌ أفقية قصيرة حين يظهر خطأٌ جديد** — «هذا هو الحقل الذي لم يُقبل».
///
/// تهتزّ حين يتبدّل [error] إلى نصٍّ غير فارغ يختلف عمّا سبقه، لا بكل إعادة
/// بناء: خطأٌ ثابتٌ لا يرتجف أمام القارئ. ومع «تقليل الحركة» لا تهتزّ.
/// `CustomTextField` يستعملها وحده؛ وتُلفّ بها أي ودجةٍ لها خطأ تحقّق.
class ShakeOnError extends StatefulWidget {
  const ShakeOnError({required this.error, required this.child, super.key});

  /// نصّ الخطأ الحالي — `null` أو فارغ ⇐ لا خطأ.
  final String? error;
  final Widget child;

  @override
  State<ShakeOnError> createState() => _ShakeOnErrorState();
}

class _ShakeOnErrorState extends State<ShakeOnError>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void didUpdateWidget(ShakeOnError old) {
    super.didUpdateWidget(old);
    final error = widget.error;
    final isNew = error != null && error.isNotEmpty && error != old.error;
    if (isNew && !AppMotion.of(context).isReduced) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // ثلاث اهتزازات تخفت — سعتُها ٨ ثم صفر.
        final t = _ctrl.value;
        final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
