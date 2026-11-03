/// البالتات من `palettes/*.json` — لـ`sync_palettes.dart`.
///
/// ملفٌّ لكل بالت، واسمُه معرّفُ الثيم (`ocean.json` ⇐ `ocean`):
///
/// ```json
/// {
///   "name": { "ar": "المحيط", "en": "Ocean" },
///   "colors": { "brandSurface": "#0D3A2F", "primaryMain": "#002623", … }
/// }
/// ```
///
/// **`standard.json` إلزاميّ ومرجعُ المفاتيح**: كلُّ بالتٍ أخرى تحمل مفاتيحه
/// نفسها بلا نقصٍ ولا زيادة، لأن `AppColors.light`/`dark` تقرأ كلَّ مفتاحٍ منها.
library;

import 'cli.dart';

const standardId = 'standard';

/// بالتٌ مقروءةٌ من ملفّها.
class PaletteFile {
  const PaletteFile(this.id, this.names, this.colors);

  final String id;

  /// الاسم المعروض لكل لغة — مفتاحُها اسمُ ملف الترجمة (`ar` · `en`).
  final Map<String, String> names;

  /// اسمُ الدرجة ⇐ `0xAARRGGBB`، بترتيب الملف.
  final Map<String, int> colors;

  String get nameKey => 'themePreset${toPascalCase(id)}';
  String get dartName => toCamelCase(id);
}

/// خطأٌ بملف بالت — السكربت يطبعه سطراً ويخرج.
class PaletteError implements Exception {
  const PaletteError(this.message);

  final String message;

  @override
  String toString() => message;
}

final _id = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
final _key = RegExp(r'^[a-z][A-Za-z0-9]*$');
final _hex = RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$');

/// مفتاحُ اسمِ ثيمٍ يملكه هذا المولِّد — و`themePreset` وحده عنوانُ القسم.
bool isGeneratedNameKey(String key) =>
    RegExp(r'^themePreset[A-Z]').hasMatch(key);

/// [json] ملفُّ البالت [id] — وكلُّ لغةٍ بـ[locales] يجب أن يكون لها اسم.
PaletteFile parsePalette(String id, Object? json, Set<String> locales) {
  if (!_id.hasMatch(id)) {
    throw PaletteError(
      '$id.json: اسمُ الملف هو المعرّف — snake_case بحروفٍ لاتينية صغيرة',
    );
  }
  if (json is! Map<String, dynamic>) {
    throw PaletteError('$id.json: كائن JSON بـname · colors');
  }

  final name = json['name'];
  if (name is! Map<String, dynamic>) {
    throw PaletteError('$id.json: "name" كائنٌ بلغةٍ لكل ملف ترجمة');
  }
  final names = <String, String>{};
  for (final locale in locales) {
    final value = name[locale];
    if (value is! String || value.trim().isEmpty) {
      throw PaletteError('$id.json: "name.$locale" ناقص');
    }
    names[locale] = value.trim();
  }

  final raw = json['colors'];
  if (raw is! Map<String, dynamic> || raw.isEmpty) {
    throw PaletteError('$id.json: "colors" كائنٌ بدرجات البالت');
  }
  final colors = <String, int>{};
  for (final entry in raw.entries) {
    if (!_key.hasMatch(entry.key)) {
      throw PaletteError(
        '$id.json: "${entry.key}" ليس اسماً صالحاً (camelCase)',
      );
    }
    final value = entry.value;
    if (value is! String || !_hex.hasMatch(value)) {
      throw PaletteError(
        '$id.json: "colors.${entry.key}" لونٌ بصيغة #RRGGBB أو #AARRGGBB',
      );
    }
    final hex = value.substring(1);
    colors[entry.key] = int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  }
  return PaletteFile(id, names, colors);
}

/// [palettes] مرتّبةً و`standard` أوّلاً — وكلٌّ بمفاتيحه نفسها.
List<PaletteFile> orderAndCheck(List<PaletteFile> palettes) {
  final standard = palettes.where((p) => p.id == standardId).firstOrNull;
  if (standard == null) {
    throw const PaletteError(
      'palettes/$standardId.json غائب — هو الثيم الافتراضي ومرجعُ المفاتيح',
    );
  }
  final keys = standard.colors.keys.toSet();
  for (final p in palettes) {
    final missing = keys.difference(p.colors.keys.toSet());
    final extra = p.colors.keys.toSet().difference(keys);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw PaletteError(
        '${p.id}.json: مفاتيحُه تخالف $standardId.json'
        '${missing.isEmpty ? '' : ' — ناقص: ${missing.join(' · ')}'}'
        '${extra.isEmpty ? '' : ' — زائد: ${extra.join(' · ')}'}',
      );
    }
  }
  final others = palettes.where((p) => p.id != standardId).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  return [standard, ...others];
}

const _banner =
    '// GENERATED — dart run scripts/gen_code.dart (palettes/*.json).\n'
    '// Do not edit: the next run rewrites it.\n';

/// `lib/ui/theme/app_palette.g.dart` — صنفُ الدرجات ونسخةٌ لكل بالت.
String renderPalettes(List<PaletteFile> palettes) {
  final keys = palettes.first.colors.keys;
  final out = StringBuffer()
    ..writeln(_banner)
    ..writeln("import 'package:flutter/painting.dart';")
    ..writeln()
    ..writeln('/// درجاتُ بالتٍ واحدة — مفاتيحُ `palettes/standard.json`.')
    ..writeln('///')
    ..writeln('/// لا يُقرأ إلا بـ`AppColors.light`/`dark` (F04).')
    ..writeln('class AppPalette {')
    ..writeln('  const AppPalette({');
  for (final k in keys) {
    out.writeln('    required this.$k,');
  }
  out
    ..writeln('  });')
    ..writeln();
  for (final k in keys) {
    out.writeln('  final Color $k;');
  }
  out
    ..writeln('}')
    ..writeln()
    ..writeln('/// بالتٌ لكل ملف بـ`palettes/`.')
    ..writeln('abstract final class AppPalettes {');
  for (final p in palettes) {
    out.writeln('  static const ${p.dartName} = AppPalette(');
    for (final e in p.colors.entries) {
      out.writeln('    ${e.key}: Color(${_hexLiteral(e.value)}),');
    }
    out.writeln('  );');
  }
  out.writeln('}');
  return out.toString();
}

/// `lib/ui/theme/app_theme_presets.g.dart` — ثيمٌ لكل بالت، و`standard` أوّلاً.
String renderPresets(List<PaletteFile> palettes) {
  final out = StringBuffer()
    ..writeln(_banner)
    ..writeln("import 'package:app_template/resources/locale_keys.g.dart';")
    ..writeln("import 'package:app_template/ui/theme/app_palette.g.dart';")
    ..writeln("import 'package:app_template/ui/theme/app_theme_presets.dart';")
    ..writeln()
    ..writeln('final List<AppThemePreset> generatedThemePresets = [');
  for (final p in palettes) {
    out
      ..writeln('  AppThemePreset(')
      ..writeln("    id: '${p.id}',")
      ..writeln('    nameKey: LocaleKeys.${p.nameKey},')
      ..writeln('    palette: AppPalettes.${p.dartName},')
      ..writeln('  ),');
  }
  out.writeln('];');
  return out.toString();
}

String _hexLiteral(int argb) =>
    '0x${argb.toRadixString(16).toUpperCase().padLeft(8, '0')}';

/// [translations] بعد محو أسماء الثيمات القديمة وكتابة [palettes] — بعد
/// `themePreset` (عنوان القسم) مباشرةً، أو بالآخر إن غاب.
Map<String, dynamic> applyThemeNames(
  Map<String, dynamic> translations,
  List<PaletteFile> palettes,
  String locale,
) {
  final names = {for (final p in palettes) p.nameKey: p.names[locale]!};
  final out = <String, dynamic>{};
  var placed = false;
  for (final entry in translations.entries) {
    if (isGeneratedNameKey(entry.key)) continue;
    out[entry.key] = entry.value;
    if (entry.key == 'themePreset') {
      out.addAll(names);
      placed = true;
    }
  }
  if (!placed) out.addAll(names);
  return out;
}
