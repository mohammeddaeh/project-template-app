// ignore_for_file: avoid_print

/// **يولّد موردَي شاشة الإقلاع لأندرويد من `logo_MOW.svg` — ويطبع ثوابت فلاتر.**
///
/// ```
/// dart run scripts/gen_splash_assets.dart
/// ```
///
/// ## لماذا سكربتٌ لا ملفّاتٌ تُحرَّر
///
/// الطبقات الثلاث (رمزُ أندرويد 12+ · رسمةُ ما دونه · شاشةُ فلاتر) يجب أن تضع
/// **نفس النقطة** بمركز الشاشة و**بنفس المقاس**، وإلا قفز الشعار لحظة التسليم.
/// وأرقامُ ذلك مشتقّةٌ من هندسة الشعار نفسِه، فتحريرُ ملفٍّ منها يدوياً يفكّ
/// العقد بصمت — `dart analyze` نظيف والشعارُ يقفز.
///
/// راجع [`readme/23_STARTUP_SPLASH.md`](../readme/23_STARTUP_SPLASH.md).
library;

import 'dart:io';
import 'dart:math';

const _svgPath = 'assets/images/ministry_logo/logo_MOW.svg';
const _resDir = 'android/app/src/main/res';
const _goldFill = '#B9A779';

/// نسبةُ قطر القناع الدائري إلى ضلع لوحة الرمز بأندرويد 12+.
///
/// مواصفةُ جوجل تقول ثلثين (لوحةُ ٢٨٨dp ⇒ دائرةُ ١٩٢dp)، **وقِيست على جهاز**
/// فطابقت: لقطةٌ عند ضلع ٣٨٢ أعطت قطراً ٢٤٩٫٧ وحدة = ٠٫٦٥٣. و٠٫٦٥ خصمٌ
/// احتياطيّ للتنعيم.
const _maskRatio = 0.65;

/// مقاسُ لوحة رمز أندرويد 12+ بالـdp — من المواصفة، ولا يُملى علينا.
const _iconCanvasDp = 288.0;

void main() {
  final svg = File(_svgPath).readAsStringSync();
  final paths = RegExp(r'<path d="([^"]*)" fill="([^"]*)"')
      .allMatches(svg)
      .map((m) => (d: m[1]!, gold: m[2] == _goldFill))
      .toList();

  final pts = paths.expand((p) => _points(p.d)).toList();
  final box = _bounds(pts);
  final circle = _smallestEnclosingCircle(pts);

  // ── المرساة: مركزُ أصغر دائرةٍ تسع الشعار ────────────────────────────────
  //
  // لا مركزُ الصندوق — القناعُ دائريّ، فالمركزُ الذي يصغّر نصفَ القطر هو الذي
  // يسمح بأكبر شعارٍ غير مقصوص.
  final ax = circle.cx, ay = circle.cy, r = circle.r;
  final side = 2 * r / _maskRatio;
  final logoDp = box.w / side * _iconCanvasDp;

  final body = paths
      .map((p) => '        <path\n'
          '            android:pathData="${p.d}"\n'
          '            android:fillColor="${p.gold ? _goldFill : '#FFFFFF'}" />')
      .join('\n');

  String vector(String note, num w, num h, num vw, num vh) =>
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!-- مولَّد بـscripts/gen_splash_assets.dart من $_svgPath.\n'
      '     **لا يُحرَّر يدوياً** — راجع readme/23_STARTUP_SPLASH.md.\n'
      '     $note -->\n'
      '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
      '    android:width="${_fmt(w)}dp"\n    android:height="${_fmt(h)}dp"\n'
      '    android:viewportWidth="${_fmt(vw)}"\n'
      '    android:viewportHeight="${_fmt(vh)}">\n'
      '    <group android:translateX="${_fmt(vw / 2 - ax)}"'
      ' android:translateY="${_fmt(vh / 2 - ay)}">\n$body\n    </group>\n</vector>\n';

  File('$_resDir/drawable/splash_icon_v31.xml').writeAsStringSync(vector(
    'رمزُ SplashScreen API — يقصّه النظام بدائرةٍ قطرُها ثلثا الضلع.',
    _iconCanvasDp, _iconCanvasDp, side, side,
  ));

  // ما دون أندرويد 12: لا قناع، فيكفي أن تصير المرساةُ مركزَ المرسومة ليقع
  // الشعار حيث يقع هناك — يُمدّ الضلعُ حول المرساة، ثم `gravity="center"`.
  final vw = 2 * max(box.w - (ax - box.x), ax - box.x);
  final vh = 2 * max(box.h - (ay - box.y), ay - box.y);
  File('$_resDir/drawable/splash_logo_full.xml').writeAsStringSync(vector(
    'رسمةُ نافذة الإطلاق — المرساةُ مركزُها، فـgravity="center" يكفي.',
    logoDp * vw / box.w, logoDp * vw / box.w * vh / vw, vw, vh,
  ));

  print('صندوق الحبر  : ${_fmt(box.w)} × ${_fmt(box.h)}');
  print('المرساة      : (${_fmt(ax)}, ${_fmt(ay)})   R=${_fmt(r)}');
  print('رمز v31      : ضلع ${_fmt(side)} — الشعار ${(box.w / side * 100).toStringAsFixed(1)}٪ من اللوحة');
  print('');
  print('⚠️  انقل هذه إلى الودجة التي ترسم الشعار بفلاتر (إن وُجدت):');
  print('    static const _logoWidth       = ${logoDp.floorToDouble()};'
      '   // ≤ ${_fmt(logoDp)} وإلا قُصّ');
  print('    static const _logoAspect      = ${_fmt(box.w)} / ${_fmt(box.h)};');
  print('    static const _logoAnchorRatio = ${_fmt(ay - box.y)} / ${_fmt(box.h)};');
}

String _fmt(num v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

({double x, double y, double w, double h}) _bounds(List<Point<double>> p) {
  final xs = p.map((e) => e.x), ys = p.map((e) => e.y);
  final x = xs.reduce(min), y = ys.reduce(min);
  return (x: x, y: y, w: xs.reduce(max) - x, h: ys.reduce(max) - y);
}

/// نقاطُ مسارٍ بأوامرَ مطلقة (M·L·H·V·C·Z) — ونقاطُ التحكّم منها، فالناتج
/// **يفوق** الحبر الحقيقي ولا يقصّر عنه.
List<Point<double>> _points(String d) {
  final out = <Point<double>>[];
  final t = RegExp(r'[MLHVCZ]|-?\d*\.?\d+').allMatches(d).map((m) => m[0]!).toList();
  double cx = 0, cy = 0;
  var i = 0, cmd = '';
  while (i < t.length) {
    if (RegExp(r'^[MLHVCZ]$').hasMatch(t[i])) {
      cmd = t[i];
      i++;
      if (cmd == 'Z') continue;
    }
    double n() => double.parse(t[i++]);
    switch (cmd) {
      case 'M':
      case 'L':
        cx = n();
        cy = n();
        out.add(Point(cx, cy));
      case 'H':
        cx = n();
        out.add(Point(cx, cy));
      case 'V':
        cy = n();
        out.add(Point(cx, cy));
      case 'C':
        out..add(Point(n(), n()))..add(Point(n(), n()));
        cx = n();
        cy = n();
        out.add(Point(cx, cy));
      default:
        i++;
    }
  }
  return out;
}

/// أصغرُ دائرةٍ تسع النقاط — هبوطٌ على الشبكة من مركز الصندوق.
///
/// كافٍ هنا: الدالّة محدّبة، والدقّة المطلوبة عُشر وحدة من ٢٧٥.
({double cx, double cy, double r}) _smallestEnclosingCircle(List<Point<double>> p) {
  final b = _bounds(p);
  var cx = b.x + b.w / 2, cy = b.y + b.h / 2;
  double radius(double x, double y) =>
      p.map((e) => Point(x, y).distanceTo(e)).reduce(max);
  var best = radius(cx, cy);
  for (var step = 32.0; step > 0.01; step /= 2) {
    var moved = true;
    while (moved) {
      moved = false;
      for (final d in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        final nx = cx + d[0] * step, ny = cy + d[1] * step;
        final r = radius(nx, ny);
        if (r < best - 1e-9) { cx = nx; cy = ny; best = r; moved = true; }
      }
    }
  }
  return (cx: cx, cy: cy, r: best);
}
