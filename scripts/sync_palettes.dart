// ignore_for_file: avoid_print
/// البالتات من `palettes/*.json` — خطوةٌ بـ`gen_code.dart`.
///
/// ما يكتبه:
///   1. `lib/ui/theme/app_palette.g.dart` — صنفُ `AppPalette` ونسخةٌ لكل بالت
///   2. `lib/ui/theme/app_theme_presets.g.dart` — ثيمٌ لكل بالت
///   3. `themePreset<Id>` بكل ملف بـ`assets/translations/` — ويمحو اسمَ ثيمٍ
///      حُذفت بالته
///
/// صيغةُ الملف وقواعده بـ`scripts/src/palette_sync.dart`.
///
/// تشغيل (ضمن `dart run scripts/gen_code.dart`، أو وحده):
///   dart run scripts/sync_palettes.dart
library;

import 'dart:convert';
import 'dart:io';

import 'src/cli.dart';
import 'src/palette_sync.dart';
import 'src/translation_merge.dart';

const _palettesDir = 'palettes';
const _paletteOut = 'lib/ui/theme/app_palette.g.dart';
const _presetsOut = 'lib/ui/theme/app_theme_presets.g.dart';
const _translationsDir = 'assets/translations';

Future<void> main() => runCli(() async {
  final translations = _jsonFiles(_translationsDir);
  final locales = {for (final f in translations) _stem(f)};

  final parsed = <PaletteFile>[];
  for (final file in _jsonFiles(_palettesDir)) {
    try {
      parsed.add(
        parsePalette(_stem(file), jsonDecode(file.readAsStringSync()), locales),
      );
    } on PaletteError catch (e) {
      die(e.message);
    } on FormatException catch (e) {
      die('${_stem(file)}.json: JSON غير صالح — ${e.message}');
    }
  }
  final List<PaletteFile> palettes;
  try {
    palettes = orderAndCheck(parsed);
  } on PaletteError catch (e) {
    die(e.message);
  }

  File(_paletteOut).writeAsStringSync(renderPalettes(palettes));
  File(_presetsOut).writeAsStringSync(renderPresets(palettes));
  await Process.run('dart', [
    'format',
    _paletteOut,
    _presetsOut,
  ], runInShell: true);

  for (final file in translations) {
    final before = file.readAsStringSync();
    final map = jsonDecode(before) as Map<String, dynamic>;
    final after = encodeTranslations(
      applyThemeNames(map, palettes, _stem(file)),
    );
    // مقارنةٌ بلا `\r`: ملفٌّ بنهايات Windows لم يتغيّر مفتاحٌ فيه لا يُعاد كتابته.
    if (after != before.replaceAll('\r\n', '\n')) {
      file.writeAsStringSync(after);
    }
  }

  print('   ${palettes.length} بالت: ${palettes.map((p) => p.id).join(' · ')}');
});

List<File> _jsonFiles(String dir) =>
    Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

String _stem(File f) {
  final name = f.uri.pathSegments.last;
  return name.substring(0, name.lastIndexOf('.'));
}
