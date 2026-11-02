// ignore_for_file: avoid_print
/// جردُ مشروعٍ قديم قبل نقله إلى القالب — **عملٌ آليّ بلا اجتهاد**.
///
/// يمرّ على مستودع المشروع القديم (أي منصّة: Capacitor/Ionic · React Native ·
/// Flutter · أندرويد/iOS أصلية) ويعدّ ما فيه، ويربط كل «إشارة» بالقدرة المقابلة
/// بالقالب (`readme/06_CAPABILITIES.md`). الخطّة نفسها تُكتب بعده بskill
/// `port-to-template` — فهي اجتهاد، وهذا جرد.
///
/// | يجرد | كيف |
/// |---|---|
/// | المنصّة | `package.json` · `pubspec.yaml` · `build.gradle` · `*.xcodeproj` |
/// | الشاشات | ملفاتٌ تحت `pages/` · `screens/` · `views/` أو أسماؤها `*Page`/`*Screen`/`*View` |
/// | الـendpoints | نصوصٌ تبدأ بـ`/api/` أو `http(s)://` |
/// | الترجمات | ملفات JSON تحت `i18n/` · `locales/` · `translations/` وعدد مفاتيحها |
/// | الخطوط | كل `.ttf`/`.otf` ووزنه **من الملف** (`usWeightClass`) |
/// | SVG | عددها، وما فيه `<style>` (يُرسم أسود بـflutter_svg) |
/// | القدرات | إشاراتٌ بالكود وملفات الاعتماديات ⇐ قسمٌ بـ`06_CAPABILITIES.md` · kit · موديول — الجدول بـ`src/port_signals.dart` |
///
/// تشغيل من جذر المشروع الجديد (المبنيّ على القالب):
///   dart run scripts/port_inventory.dart ../old_project
///
/// يكتب `docs/port/inventory.md` — يُقرأ قبل كتابة `docs/PORT_PLAN.md`.
library;

import 'dart:io';

import 'src/port_signals.dart';
import 'sync_fonts.dart' show fontFileWeight;

const _skip = {
  'node_modules',
  '.git',
  'build',
  'dist',
  'www',
  '.dart_tool',
  'Pods',
  '.gradle',
  '.idea',
  '.angular',
  'coverage',
  '.next',
};
const _codeExt = [
  '.ts',
  '.tsx',
  '.js',
  '.jsx',
  '.vue',
  '.dart',
  '.kt',
  '.java',
  '.swift',
  '.html',
];

void main(List<String> args) {
  if (args.isEmpty || !Directory(args.first).existsSync()) {
    print('usage: dart run scripts/port_inventory.dart <old_project_dir>');
    exit(64);
  }
  final root = Directory(args.first).absolute.path.replaceAll(r'\', '/');
  print('\n📦  port_inventory — $root\n');

  final files = _walk(Directory(root)).where((f) => !_bundled(f.path)).toList();
  String rel(File f) => f.path.replaceAll(r'\', '/').substring(root.length + 1);

  final stack = _stack(root);
  final code = files.where((f) => _codeExt.any(f.path.endsWith)).toList();
  final contents = {for (final f in code) rel(f): _read(f)};

  final screens = [
    for (final path in contents.keys)
      if (RegExp(r'/(pages|screens|views)/').hasMatch('/$path') ||
          RegExp(
            r'(Page|Screen|View)\.(tsx?|jsx?|vue|dart|kt|swift)$',
          ).hasMatch(path))
        path,
  ]..sort();

  final endpoints = <String>{};
  final endpoint = RegExp(
    r'''['"`]((?:https?://[^'"`\s]+)|(?:/api/[^'"`\s]*))['"`]''',
  );
  for (final text in contents.values) {
    for (final m in endpoint.allMatches(text)) {
      endpoints.add(m.group(1)!);
    }
  }

  final translations = [
    for (final f in files)
      if (f.path.endsWith('.json') &&
          RegExp(
            r'[\\/](i18n|locales?|translations|lang)[\\/]',
          ).hasMatch(f.path))
        '${rel(f)}  (${RegExp(r'"\s*:').allMatches(_read(f)).length} مفتاحاً تقريباً)',
  ]..sort();

  final fonts = [
    for (final f in files)
      if (f.path.endsWith('.ttf') || f.path.endsWith('.otf'))
        '${rel(f)}  — وزن الملف ${fontFileWeight(f) ?? '؟'}',
  ]..sort();

  final svgs = files.where((f) => f.path.endsWith('.svg')).toList();
  final styled = [
    for (final f in svgs)
      if (_read(f).contains('<style')) rel(f),
  ]..sort();

  // الإشارات تُطابَق على الكود **وملفات الاعتماديات والأنماط**: اسمُ حزمةٍ
  // بـ`package.json` أو `build.gradle` يكفي ليُلتقط ما لم يُستدعَ بعد.
  final signals = scanPortSignals({
    ...contents,
    for (final f in files)
      if (portManifestNames.contains(f.uri.pathSegments.last) ||
          portStyleExtensions.any(f.path.endsWith))
        rel(f): _read(f),
  });

  final out = StringBuffer()
    ..writeln('# جرد المشروع القديم')
    ..writeln()
    ..writeln(
      '> مولَّد بـ`dart run scripts/port_inventory.dart $root` — لا يُحرَّر.',
    )
    ..writeln(
      '> يُقرأ قبل `docs/PORT_PLAN.md`، وكل إشارةٍ أدناه تُطابَق بقدرةٍ من',
    )
    ..writeln('> `readme/06_CAPABILITIES.md` قبل كتابة أي أداة.')
    ..writeln()
    ..writeln('| | |')
    ..writeln('|---|---|')
    ..writeln('| المنصّة | $stack |')
    ..writeln('| ملفات الكود | ${code.length} |')
    ..writeln('| الشاشات | ${screens.length} |')
    ..writeln('| الـendpoints | ${endpoints.length} |')
    ..writeln('| ملفات الترجمة | ${translations.length} |')
    ..writeln('| الخطوط | ${fonts.length} |')
    ..writeln('| SVG | ${svgs.length} · بـ`<style>`: ${styled.length} |')
    ..writeln()
    ..writeln('## القدرات — إشارةٌ بالمشروع القديم ⇐ ما يقابلها بالقالب')
    ..writeln()
    ..writeln('| الإشارة | ملفات | بالقالب | أمثلة |')
    ..writeln('|---|---|---|---|');
  for (final (signal, hits) in signals) {
    out.writeln(
      '| ${signal.name} | ${hits.length} | ${signal.target} | ${hits.take(3).map((h) => '`$h`').join(' · ')} |',
    );
  }
  void list(String title, Iterable<String> items, [String? note]) {
    out
      ..writeln()
      ..writeln('## $title (${items.length})')
      ..writeln();
    if (note != null) {
      out
        ..writeln(note)
        ..writeln();
    }
    for (final i in items) {
      out.writeln('- `$i`');
    }
  }

  list('الشاشات', screens);
  list(
    'الـendpoints',
    endpoints.toList()..sort(),
    'كلٌّ منها ثابتٌ بـ`ApiUrls` — راجع `readme/17_SERVED_CONTRACT.md`.',
  );
  list('الترجمات', translations);
  list(
    'الخطوط',
    fonts,
    'سجّل كلَّ ملفٍّ **بوزنه من الملف** — `sync_fonts.dart` يفعل ذلك، و`test/font_weights_test.dart` يحرسه.',
  );
  list(
    'SVG بـ`<style>`',
    styled,
    '`dart run scripts/svg_inline_styles.dart <الملف>` لكلٍّ منها بعد نسخه إلى `assets/`.',
  );

  final target = File('docs/port/inventory.md')..createSync(recursive: true);
  target.writeAsStringSync(out.toString());
  print(
    '   ${screens.length} شاشة · ${endpoints.length} endpoint · ${signals.length} إشارة قدرة',
  );
  print('   ✓ docs/port/inventory.md\n');
}

/// ناتجُ بناءٍ لا مصدر: حزمٌ مضغوطة بأسماءٍ مُجزَّأة (`App-BIj2GB2r.js`)، ونسخة
/// الويب داخل مشروعَي أندرويد/iOS (`src/main/assets/public/` · `App/App/public/`)،
/// ومجلدات `build-*`، وكودٌ مولَّد (`*.g.dart` · `GeneratedPluginRegistrant`).
/// عدُّها يضاعف كل إشارة بنسخٍ مولَّدة.
bool _bundled(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.endsWith('.min.js') ||
      RegExp(r'-[A-Za-z0-9_-]{8}\.(js|css)$').hasMatch(p) ||
      p.contains('/src/main/assets/public/') ||
      p.contains('/App/App/public/') ||
      RegExp(r'/build-[^/]+/').hasMatch(p) ||
      RegExp(r'\.(g|freezed|gen|gr|config)\.dart$').hasMatch(p) ||
      p.contains('GeneratedPluginRegistrant');
}

Iterable<File> _walk(Directory dir) sync* {
  for (final e in dir.listSync(followLinks: false)) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is Directory) {
      if (_skip.contains(name)) continue;
      yield* _walk(e);
    } else if (e is File) {
      yield e;
    }
  }
}

String _read(File f) {
  try {
    return f.readAsStringSync();
  } on FileSystemException {
    return '';
  }
}

String _stack(String root) {
  final found = <String>[];
  bool has(String p) => File('$root/$p').existsSync();
  if (has('package.json')) {
    final pkg = _read(File('$root/package.json'));
    if (pkg.contains('@capacitor/')) found.add('Capacitor');
    if (pkg.contains('@ionic/')) found.add('Ionic');
    if (pkg.contains('react-native')) {
      found.add('React Native');
    } else if (pkg.contains('"react"')) {
      found.add('React');
    }
    if (pkg.contains('"vue"')) found.add('Vue');
    if (pkg.contains('@angular/core')) found.add('Angular');
    if (found.isEmpty) found.add('Node/JS');
  }
  if (has('pubspec.yaml')) found.add('Flutter');
  if (has('android/app/build.gradle') ||
      has('app/build.gradle') ||
      has('android/app/build.gradle.kts')) {
    found.add('Android');
  }
  if (Directory(root).listSync().any((e) => e.path.endsWith('.xcodeproj')) ||
      Directory('$root/ios').existsSync()) {
    found.add('iOS');
  }
  return found.isEmpty ? 'غير معروفة' : found.join(' · ');
}
