import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:app_template/ui/theme/app_motion.dart';

/// تبديلُ الثيم بدائرةٍ تتّسع من الزرّ — للوضع (فاتح · داكن) وللبالت معاً.
///
/// يُركَّب **مرّةً** فوق كل المسارات (`MaterialApp.builder` بـ`app.dart`)،
/// ويُنادى من زرّ التبديل:
///
/// ```dart
/// ThemeReveal.run(context, () => context.setThemeMode(mode));
/// ```
///
/// [run] تأخذ **سياقَ الزرّ نفسه**: منتصفُه مركزُ الدائرة.
///
/// تُلتقط الشاشةُ صورةً وتُوضع فوقها، ثم يُطبَّق الثيم تحتها، وتُفتح في الصورة
/// دائرةٌ حتى تكشف الشاشة كلّها. واللمسُ محجوبٌ طوال الحركة: الصورة ليست
/// الشاشة، وضغطةٌ عليها تصل إلى ما تحتها.
///
/// **ويُطبَّق التغيير فوراً بلا حركة** مع «تقليل الحركة» · حين لا [ThemeReveal]
/// فوق الزرّ · حين يفشل الالتقاط · أو أثناء حركةٍ قائمة.
///
/// ⚠️ ما يرسمه المحرّك خارج فلاتر (فيديو · خريطة — platform view) يظهر بالصورة
/// فارغاً أو متجمّداً طوال الحركة.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({super.key, required this.child});

  final Widget child;

  /// [change] يبدّل الثيم — يُنادى مرّةً واحدة، بحركةٍ أو بدونها.
  static Future<void> run(BuildContext context, VoidCallback change) async {
    final state = context.findAncestorStateOfType<_ThemeRevealState>();
    final button = context.findRenderObject();
    final reduced = AppMotion.of(context).slow == Duration.zero;
    if (state == null || reduced || button is! RenderBox || !button.hasSize) {
      change();
      return;
    }
    await state._reveal(
      button.localToGlobal(button.size.center(Offset.zero)),
      change,
    );
  }

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _progress;

  ui.Image? _image;
  Offset _origin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _clear();
      });
    _progress = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.slowCurve,
    );
  }

  Future<void> _reveal(Offset globalOrigin, VoidCallback change) async {
    if (_image != null) {
      change();
      return;
    }
    final boundary = _boundary.currentContext?.findRenderObject();
    ui.Image? image;
    if (boundary is RenderRepaintBoundary) {
      try {
        image = await boundary.toImage(
          pixelRatio: View.of(context).devicePixelRatio,
        );
      } catch (_) {
        // الالتقاطُ زينةٌ لا شرط — الثيم يتبدّل بلا حركة.
      }
    }
    if (!mounted || image == null) {
      image?.dispose();
      change();
      return;
    }
    final self = context.findRenderObject()! as RenderBox;
    setState(() {
      _image = image;
      _origin = self.globalToLocal(globalOrigin);
    });
    change();
    _controller.forward(from: 0);
  }

  void _clear() {
    if (!mounted) return;
    setState(() {
      _image?.dispose();
      _image = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (image != null)
          Positioned.fill(
            child: AbsorbPointer(
              child: CustomPaint(
                painter: _RevealPainter(image, _origin, _progress),
              ),
            ),
          ),
      ],
    );
  }
}

/// الصورةُ القديمة بثقبٍ دائريّ يتّسع من [origin] حتى أبعد زاوية.
class _RevealPainter extends CustomPainter {
  _RevealPainter(this.image, this.origin, this.progress)
    : super(repaint: progress);

  final ui.Image image;
  final Offset origin;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final farthest = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - origin).distance).reduce(math.max);
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(
        Rect.fromCircle(center: origin, radius: farthest * progress.value),
      );
    canvas.clipPath(hole);
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
    );
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.image != image || old.origin != origin;
}
