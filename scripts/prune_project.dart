// ignore_for_file: avoid_print
/// تنظيف المشروع بعد النقل أو الإنهاء — **ما لا يستعمله أحد**.
///
/// | الصنف | يُكتشف حين | مع `--apply` |
/// |---|---|---|
/// | مفتاح ترجمة | لا `LocaleKeys.<اسمه>` ولا نصُّه حرفياً بـ`lib/` | **يُحذف** من كل `assets/translations/*.json` |
/// | أصل (صورة · SVG · Lottie) | لا مسارُه ولا اسمُ getter بـ`assets.gen.dart` بـ`lib/` ولا مسارُه بـ`scripts/` وملفات YAML الجذر وموارد أندرويد/iOS | **يُحذف** الملف |
/// | موديول | علَمه بـ`AppFeatures` مطفأ | يُعرض وحسب — الحذف بخطوات `SETUP.md` كل موديول |
/// | ملف Dart | لا يستورده أحد ولا هو مدخل (`main.dart` · مولَّد · `part`) | يُعرض وحسب |
/// | حزمة | بـ`dependencies` ولا `import` لها بـ`lib/` `test/` `scripts/` | يُعرض وحسب — بعضُها إضافاتُ منصّةٍ بلا import |
///
/// **وما لا يراه الفحص يُحمى بـ`.prune_keep`** — سطرٌ لكل اسم أو مسار (يقبل `*`):
/// مفتاحٌ يرسله الخادم (`messageKey`) لا يظهر بالكود أبداً، فيبدو مهجوراً وليس كذلك.
///
/// تشغيل من جذر المشروع — وشجرة git نظيفة مع `--apply`:
///   dart run scripts/prune_project.dart            # تقريرٌ فقط
///   dart run scripts/prune_project.dart --apply    # يحذف المفاتيح والأصول
///
/// ثم: `dart run scripts/gen_code.dart` · `dart analyze` · `flutter test`.
library;

import 'dart:convert';
import 'dart:io';

const _translations = 'assets/translations';
const _assetsGen = 'lib/resources/assets.gen.dart';
const _localeKeys = 'lib/resources/locale_keys.g.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  print(
    '\n🧹  prune_project — ${apply ? 'تطبيق' : 'تقريرٌ فقط (--apply للحذف)'}\n',
  );
  if (apply && !_cleanTree()) {
    print(
      '❌  شجرة git فيها تغييرات — احفظها أولاً، ليكون التنظيف commitاً منفصلاً.',
    );
    exit(2);
  }

  final keep = _readKeep();
  final source = _dartSource(['lib'], skipGenerated: true);

  final keys = _unusedKeys(source, keep);
  _section('مفاتيح ترجمة بلا مستعمل', keys);
  // الأصل يُستعمل خارج `lib/` أيضاً: سكربتٌ يولّد منه (شاشة الإقلاع) أو ملفُّ
  // إعدادٍ يسمّيه (`flutter_native_splash.yaml` · أيقونات flavors) أو موردٌ أصليّ.
  final assets = _unusedAssets('$source${_configSource()}', keep);
  _section('أصولٌ بلا مستعمل', assets);
  _section(
    'موديولاتٌ علَمها مطفأ (راجع SETUP.md كلٍّ منها قبل حذفه)',
    _offModules(),
  );
  _section('ملفات Dart لا يستوردها أحد', _orphanFiles(keep));
  _section('حزمٌ بلا import', _unusedPackages(keep));

  if (!apply) {
    print('   تقريرٌ فقط — لم يُحذف شيء.\n');
    return;
  }
  _removeKeys(keys);
  for (final path in assets) {
    File(path).deleteSync();
  }
  print('   ✓ حُذف ${keys.length} مفتاحاً و${assets.length} أصلاً.');
  print(
    '   التالي: dart run scripts/gen_code.dart · dart analyze · flutter test\n',
  );
}

void _section(String title, List<String> items) {
  print('── $title (${items.length}) ──');
  for (final i in items) {
    print('   $i');
  }
  print('');
}

// ── keep ──────────────────────────────────────────────────────────────────────

List<RegExp> _readKeep() {
  final file = File('.prune_keep');
  if (!file.existsSync()) return const [];
  return file
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .map((l) => RegExp('^${RegExp.escape(l).replaceAll(r'\*', '.*')}\$'))
      .toList();
}

bool _kept(List<RegExp> keep, String name) => keep.any((k) => k.hasMatch(name));

// ── sources ───────────────────────────────────────────────────────────────────

String _rel(String path) =>
    path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

bool _generated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.gr.dart') ||
    path.endsWith('.config.dart');

Iterable<File> _dartFiles(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) yield e;
  }
}

String _dartSource(List<String> roots, {required bool skipGenerated}) {
  final buffer = StringBuffer();
  for (final root in roots) {
    for (final f in _dartFiles(root)) {
      final path = _rel(f.path);
      if (skipGenerated && _generated(path)) continue;
      if (path == _assetsGen) continue;
      buffer.writeln(f.readAsStringSync());
    }
  }
  return buffer.toString();
}

/// كل ما يسمّي أصلاً خارج `lib/`: سكربتات · YAML الجذر · موارد أندرويد وiOS النصّية.
String _configSource() {
  final buffer = StringBuffer(_dartSource(['scripts'], skipGenerated: true));
  for (final f in Directory('.').listSync().whereType<File>()) {
    if (f.path.endsWith('.yaml') && !f.path.endsWith('pubspec.yaml')) {
      buffer.writeln(f.readAsStringSync());
    }
  }
  for (final root in ['android/app/src/main/res', 'ios/Runner']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (f.path.endsWith('.xml') || f.path.endsWith('.plist')) {
        buffer.writeln(f.readAsStringSync());
      }
    }
  }
  return buffer.toString();
}

// ── translation keys ──────────────────────────────────────────────────────────

List<String> _unusedKeys(String source, List<RegExp> keep) {
  final file = File(_localeKeys);
  if (!file.existsSync()) return const [];
  final keys = RegExp(
    r"static const (\w+) = '([^']+)'",
  ).allMatches(file.readAsStringSync()).map((m) => (m.group(1)!, m.group(2)!));
  return [
    for (final (name, value) in keys)
      if (!source.contains('LocaleKeys.$name') &&
          !source.contains("'$value'") &&
          !source.contains('"$value"') &&
          !_kept(keep, value))
        value,
  ]..sort();
}

void _removeKeys(List<String> keys) {
  if (keys.isEmpty) return;
  final dir = Directory(_translations);
  if (!dir.existsSync()) return;
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final key in keys) {
      final parts = key.split('.');
      Map<String, dynamic>? node = json;
      for (var i = 0; i < parts.length - 1 && node != null; i++) {
        final next = node[parts[i]];
        node = next is Map<String, dynamic> ? next : null;
      }
      node?.remove(parts.last);
    }
    f.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
  }
}

// ── assets ────────────────────────────────────────────────────────────────────

List<String> _unusedAssets(String source, List<RegExp> keep) {
  final gen = File(_assetsGen);
  if (!gen.existsSync()) return const [];
  final getters = RegExp(
    r"get (\w+) =>\s*(?:const \w+\()?'([^']+)'",
  ).allMatches(gen.readAsStringSync()).map((m) => (m.group(1)!, m.group(2)!));
  return [
    for (final (getter, path) in getters)
      if (!source.contains('.$getter') &&
          !source.contains(path) &&
          File(path).existsSync() &&
          !_kept(keep, path))
        path,
  ]..sort();
}

// ── modules ───────────────────────────────────────────────────────────────────

List<String> _offModules() {
  final features = File('lib/core/platform/features/app_features.dart');
  final modules = Directory('lib/modules');
  if (!features.existsSync() || !modules.existsSync()) return const [];
  final flags = {
    for (final m in RegExp(
      r'static const (\w+) = (true|false);',
    ).allMatches(features.readAsStringSync()))
      m.group(1)!: m.group(2) == 'true',
  };
  String camel(String s) =>
      s.replaceAllMapped(RegExp(r'_(\w)'), (m) => m.group(1)!.toUpperCase());
  final out = <String>[];
  for (final dir in modules.listSync().whereType<Directory>()) {
    final name = _rel(dir.path).split('/').last;
    final flag = flags.entries
        .where((e) => e.key.toLowerCase() == camel(name).toLowerCase())
        .firstOrNull;
    if (flag != null && !flag.value) {
      final files = dir.listSync(recursive: true).whereType<File>().length;
      out.add(
        'lib/modules/$name/  ($files ملفاً · AppFeatures.${flag.key} = false)',
      );
    }
  }
  return out..sort();
}

// ── orphan files ──────────────────────────────────────────────────────────────

List<String> _orphanFiles(List<RegExp> keep) {
  final all = [
    for (final f in _dartFiles('lib'))
      if (!_generated(_rel(f.path))) _rel(f.path),
  ];
  final everything = _dartSource(['lib', 'test'], skipGenerated: false);
  final out = <String>[];
  for (final path in all) {
    if (path == 'lib/main.dart') continue;
    final content = File(path).readAsStringSync();
    if (RegExp(r'^part of ', multiLine: true).hasMatch(content)) continue;
    final name = path.split('/').last;
    final inLib = path.substring('lib/'.length);
    // Imported by package path, or by a relative path ending in its name.
    if (everything.contains(inLib) ||
        everything.contains("/$name'") ||
        everything.contains("'$name'")) {
      continue;
    }
    if (_kept(keep, path)) continue;
    out.add(path);
  }
  return out..sort();
}

// ── packages ──────────────────────────────────────────────────────────────────

List<String> _unusedPackages(List<RegExp> keep) {
  final pubspec = File('pubspec.yaml').readAsLinesSync();
  final deps = <String>[];
  var inDeps = false;
  for (final line in pubspec) {
    if (RegExp(r'^\S').hasMatch(line)) {
      inDeps = line.startsWith('dependencies:');
    }
    if (!inDeps) continue;
    final m = RegExp(r'^  (\w+):').firstMatch(line);
    if (m != null && m.group(1) != 'flutter') deps.add(m.group(1)!);
  }
  final source = _dartSource(['lib', 'test', 'scripts'], skipGenerated: false);
  return [
    for (final dep in deps)
      if (!source.contains('package:$dep/') && !_kept(keep, dep)) dep,
  ]..sort();
}

bool _cleanTree() {
  final r = Process.runSync('git', ['status', '--porcelain']);
  return r.exitCode == 0 && (r.stdout as String).trim().isEmpty;
}
