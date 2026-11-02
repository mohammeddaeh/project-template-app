import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// The strokes drawn on a [SignaturePad] — kept as points with their times,
/// so the same drawing is a signature image ([toPng]) or ink a recogniser
/// reads ([strokes]).
class InkController extends ChangeNotifier {
  final _strokes = <List<InkPoint>>[];
  Size _canvas = Size.zero;

  List<InkStroke> get strokes => [for (final s in _strokes) InkStroke(s)];
  bool get isEmpty => _strokes.isEmpty;

  void _begin(Offset p) {
    _strokes.add([_point(p)]);
    notifyListeners();
  }

  void _extend(Offset p) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(_point(p));
    notifyListeners();
  }

  InkPoint _point(Offset p) =>
      InkPoint(p.dx, p.dy, DateTime.now().millisecondsSinceEpoch);

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  /// The drawing as a PNG at the pad's size, in [color] on a transparent
  /// ground — `null` when nothing is drawn.
  Future<Uint8List?> toPng({required Color color, double width = 3}) async {
    if (isEmpty || _canvas.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    _paintStrokes(Canvas(recorder), _strokes, color, width);
    final image = await recorder.endRecording().toImage(
      _canvas.width.ceil(),
      _canvas.height.ceil(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}

/// A box to draw in with a finger or stylus — a signature, or handwriting for
/// `HandwritingInput`. No kit: drawing is plain Flutter.
///
/// The drawing lives in [controller]: [InkController.toPng] for a signature
/// image (save it as an attachment like a captured photo), or
/// [InkController.strokes] for a recogniser.
class SignaturePad extends StatelessWidget {
  const SignaturePad({super.key, required this.controller, this.hint});

  final InkController controller;

  /// Shown faintly while the pad is empty — "sign here".
  final String? hint;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    return SizedBox(
      height: context.screen.size(160),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: colors.borderSubtle),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            controller._canvas = box.biggest;
            return ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Stack(
                fit: StackFit.expand,
                children: [
                  if (controller.isEmpty && hint != null)
                    Center(
                      child: Text(
                        hint!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onPanStart: (d) => controller._begin(d.localPosition),
                    onPanUpdate: (d) => controller._extend(d.localPosition),
                    child: CustomPaint(
                      painter: _InkPainter(
                        controller._strokes,
                        colors.textPrimary,
                      ),
                    ),
                  ),
                  if (!controller.isEmpty)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: IconButton(
                        tooltip: LocaleKeys.inkClear.tr(),
                        onPressed: controller.clear,
                        icon: Icon(
                          Icons.backspace_outlined,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes, this.color);

  final List<List<InkPoint>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      _paintStrokes(canvas, strokes, color, 3);

  // The list is mutated in place as the finger moves — always repaint.
  @override
  bool shouldRepaint(_InkPainter old) => true;
}

void _paintStrokes(
  Canvas canvas,
  List<List<InkPoint>> strokes,
  Color color,
  double width,
) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  for (final stroke in strokes) {
    if (stroke.length == 1) {
      canvas.drawCircle(
        Offset(stroke.first.x, stroke.first.y),
        width / 2,
        paint..style = PaintingStyle.fill,
      );
      paint.style = PaintingStyle.stroke;
      continue;
    }
    final path = Path()..moveTo(stroke.first.x, stroke.first.y);
    for (final p in stroke.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    canvas.drawPath(path, paint);
  }
}
