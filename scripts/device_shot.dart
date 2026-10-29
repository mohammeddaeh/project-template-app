// ignore_for_file: avoid_print
/// لقطةُ شاشةٍ من جهاز أندرويد موصول، **بجانب لقطة التطبيق القديم** — للنقل.
///
/// مقارنةُ نسخة Flutter بالتطبيق الأصلي **بقراءة الكود** تخطئ في ربط الشاشات
/// بلقطاتها. والتشغيل على جهاز ووضع اللقطتين متجاورتين يكشف الفروق الحقيقية.
///
/// | يكتب | ما فيه |
/// |---|---|
/// | `docs/port/shots/<name>.png` | اللقطة (`adb exec-out screencap -p`) |
/// | `docs/port/shots/<name>.txt` | نصوص الشاشة ووصف عناصرها (`uiautomator dump`) — للتنقّل بالاسم ومقارنة النصّ |
/// | `docs/port/shots/<name>.html` | مع `--ref`: اللقطتان متجاورتان بنفس العرض |
///
/// ⚠️ **العرضُ المنطقيّ يُطبع مع كل لقطة** (`wm size` ÷ `wm density` × 160): هاتفان
/// بعرضين منطقيين مختلفين يجعلان فرق الحجم وحده بلا معنى — قارن على جهازٍ واحد،
/// أو على جهازين بالعرض المنطقيّ نفسه.
///
/// تشغيل والتطبيق مفتوحٌ على الشاشة المطلوبة:
///   dart run scripts/device_shot.dart home
///   dart run scripts/device_shot.dart home --ref docs/port/reference/home.png
///   dart run scripts/device_shot.dart home --serial emulator-5554
library;

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final name = args.firstWhere((a) => !a.startsWith('--'), orElse: () => '');
  if (name.isEmpty) {
    print(
      'usage: dart run scripts/device_shot.dart <name> [--ref ref.png] [--serial ID]',
    );
    exit(64);
  }
  String? option(String flag) {
    final i = args.indexOf(flag);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final serial = option('--serial');
  List<String> adb(List<String> rest) => [
    if (serial != null) ...['-s', serial],
    ...rest,
  ];

  final dir = Directory('docs/port/shots')..createSync(recursive: true);
  final png = File('${dir.path}/$name.png');

  final shot = Process.runSync(
    'adb',
    adb(['exec-out', 'screencap', '-p']),
    stdoutEncoding: null,
  );
  if (shot.exitCode != 0) {
    print(
      '❌  adb screencap فشل — هل الجهاز موصول (adb devices)؟\n${shot.stderr}',
    );
    exit(2);
  }
  png.writeAsBytesSync(shot.stdout as List<int>);

  final width = _logicalWidth(adb);
  final texts = _screenTexts(adb);
  File('${dir.path}/$name.txt').writeAsStringSync('${texts.join('\n')}\n');

  print(
    '   ✓ ${png.path}  (عرضٌ منطقيّ ${width ?? '؟'}dp · ${texts.length} نصّاً)',
  );

  final ref = option('--ref');
  if (ref != null) {
    final html = File('${dir.path}/$name.html');
    final refPath = File(ref).absolute.uri.toString();
    html.writeAsStringSync('''<!doctype html><meta charset="utf-8">
<title>$name</title>
<style>body{margin:16px;font:14px sans-serif;display:flex;gap:16px}figure{margin:0}img{width:360px;border:1px solid #ccc}</style>
<figure><img src="$refPath"><figcaption>المرجع</figcaption></figure>
<figure><img src="$name.png"><figcaption>Flutter — ${width ?? '؟'}dp</figcaption></figure>
''');
    print('   ✓ ${html.path}');
  }
}

int? _logicalWidth(List<String> Function(List<String>) adb) {
  final size =
      Process.runSync('adb', adb(['shell', 'wm', 'size'])).stdout as String;
  final density =
      Process.runSync('adb', adb(['shell', 'wm', 'density'])).stdout as String;
  int? last(String text, RegExp re) {
    final all = re.allMatches(text).toList();
    return all.isEmpty ? null : int.tryParse(all.last.group(1)!);
  }

  final px = last(size, RegExp(r'(\d+)x\d+'));
  final dpi = last(density, RegExp(r'(\d+)'));
  return px == null || dpi == null || dpi == 0
      ? null
      : (px * 160 / dpi).round();
}

List<String> _screenTexts(List<String> Function(List<String>) adb) {
  Process.runSync(
    'adb',
    adb(['shell', 'uiautomator', 'dump', '/sdcard/ui.xml']),
  );
  // UTF-8 صراحةً: ترميز الطرفيّة الافتراضي بويندوز يشوّه النصّ العربي.
  final xml =
      Process.runSync(
            'adb',
            adb(['exec-out', 'cat', '/sdcard/ui.xml']),
            stdoutEncoding: utf8,
          ).stdout
          as String;
  // لا يُترك تفريغُ الشاشة على الجهاز — فيه نصوص ما كان معروضاً.
  Process.runSync('adb', adb(['shell', 'rm', '-f', '/sdcard/ui.xml']));
  final out = <String>[];
  for (final m in RegExp(r'(?:text|content-desc)="([^"]+)"').allMatches(xml)) {
    final value = _unescape(m.group(1)!).trim();
    if (value.isNotEmpty) out.add(value);
  }
  return out;
}

/// كيانات XML بـ`uiautomator dump` (`&#10;` · `&amp;` …) إلى نصّها.
String _unescape(String s) => s
    .replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    )
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
