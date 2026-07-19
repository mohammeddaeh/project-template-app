// ignore_for_file: avoid_print
/// Font sync tool — تفاعلي لإضافة وإدارة خيارات الخطوط.
///
/// ما يفعله:
///   1. يكتشف عائلات الخطوط تلقائياً من assets/fonts/ (بما فيها المجلدات الفرعية)
///   2. يسجّل الخطوط في pubspec.yaml
///   3. يسألك عن خيارات الخط للمستخدم (الاسم/العربي/اللاتيني/العائلة)
///   4. يُحدِّث lib/core/infra/config/app_fonts.dart
///
/// تشغيل:
///   dart run scripts/sync_fonts.dart
///
/// هيكل المجلدات المدعوم:
///   assets/fonts/Cairo-Regular.ttf          ← ملف مباشر
///   assets/fonts/NotoSans/NotoSans-Bold.ttf ← مجلد فرعي باسم العائلة
///   assets/fonts/0/NotoSans-Bold.ttf        ← مجلد فرعي بأي اسم
library;

import 'dart:convert';
import 'dart:io';

// ── Weight map ────────────────────────────────────────────────────────────────
const _weightMap = <String, int>{
  'thin': 100,
  'extralight': 200,
  'extrathin': 200,
  'ultralight': 200,
  'light': 300,
  'regular': 400,
  'medium': 500,
  'semibold': 600,
  'demibold': 600,
  'bold': 700,
  'extrabold': 800,
  'ultrabold': 800,
  'heavy': 900,
  'black': 900,
};

// ── Markers ───────────────────────────────────────────────────────────────────
const _pubspecStart =
    '  # ================== Auto-Generated Fonts ==================';
const _pubspecEnd = '  # End of auto-generated fonts';
const _dartStart =
    '  // ── BEGIN GENERATED — dart run scripts/sync_fonts.dart ───────────────────';
const _dartEnd =
    '  // ── END GENERATED ─────────────────────────────────────────────────────────';

// ── Entry point ───────────────────────────────────────────────────────────────

void main() {
  // Force UTF-8 I/O on Windows so Arabic labels are read/written correctly.
  stdout.supportsAnsiEscapes; // warm-up
  stdin.echoMode = true;
  stdin.lineMode = true;

  _printHeader();

  // 1. اكتشاف عائلات الخطوط
  final families = _discoverFamilies();
  if (families.isEmpty) {
    _warn('No .ttf/.otf files found in assets/fonts/ — nothing to sync.');
    exit(0);
  }

  _printFamilies(families);

  // 2. تحديث pubspec.yaml بكل العائلات المكتشفة
  _syncPubspec(families);

  // 3. التفاعل مع المستخدم لتكوين خيارات الخط
  print('\n${'─' * 60}');
  print('📝  Configure font options for Settings → Typography');
  print('    Users will see these options at runtime (no restart needed).');
  print('${'─' * 60}\n');

  final familyNames = families.keys.toList();
  final options = <_FontOption>[];

  while (true) {
    final opt = _promptFontOption(familyNames, options.length + 1, options);
    if (opt == null) break;
    options.add(opt);

    print('\n✔  Option "${opt.key}" added.');
    if (!_confirm('\nAdd another font option?', defaultYes: false)) break;
    print('');
  }

  if (options.isEmpty) {
    _warn('No options configured — app_fonts.dart not updated.');
    print('\n✅  pubspec.yaml updated.\n');
    exit(0);
  }

  // 4. اختيار الخط الافتراضي
  final defaultKey = _pickDefault(options);

  // 5. تحديث app_fonts.dart
  _syncAppFonts(options, defaultKey);

  print('\n✅  Done! Run: flutter pub get\n');
}

// ── Discovery ─────────────────────────────────────────────────────────────────

Map<String, List<_FontFile>> _discoverFamilies() {
  final fontsDir = Directory('assets/fonts');
  if (!fontsDir.existsSync()) {
    _error('assets/fonts/ not found. Run from project root.');
    exit(1);
  }

  final families = <String, List<_FontFile>>{};

  // مسح تكراري — الملفات المباشرة والمجلدات الفرعية
  _collectFontFiles(fontsDir, families);

  // ترتيب داخل كل عائلة
  for (final files in families.values) {
    files.sort((a, b) => a.weight.compareTo(b.weight));
  }

  return families;
}

void _collectFontFiles(Directory dir, Map<String, List<_FontFile>> families) {
  for (final entity in dir.listSync()) {
    if (entity is File) {
      final path = entity.path.replaceAll('\\', '/');
      if (!path.endsWith('.ttf') && !path.endsWith('.otf')) continue;

      final name = entity.uri.pathSegments.last;
      final stem = name.replaceAll(RegExp(r'\.(ttf|otf)$'), '');
      final dashIdx = stem.indexOf('-');

      final String family;
      final String suffix;

      if (dashIdx == -1) {
        family = stem;
        suffix = 'regular';
      } else {
        family = stem.substring(0, dashIdx);
        suffix = stem.substring(dashIdx + 1).toLowerCase();
      }

      final isItalic = suffix.contains('italic');
      final cleanSuffix = suffix.replaceAll('italic', '').trim();
      final weight = _weightMap[cleanSuffix] ?? 400;

      // المسار النسبي من جذر المشروع
      final assetPath = _relativePath(entity.path);

      families
          .putIfAbsent(family, () => [])
          .add(_FontFile(asset: assetPath, weight: weight, isItalic: isItalic));
    } else if (entity is Directory) {
      _collectFontFiles(entity, families);
    }
  }
}

String _relativePath(String fullPath) {
  final normalized = fullPath.replaceAll('\\', '/');
  final idx = normalized.indexOf('assets/fonts');
  return idx == -1 ? normalized : normalized.substring(idx);
}

// ── Print helpers ─────────────────────────────────────────────────────────────

void _printHeader() {
  print('');
  print('╔══════════════════════════════════════════════════════════╗');
  print('║              sync_fonts — Font Configuration             ║');
  print('╚══════════════════════════════════════════════════════════╝');
  print('');
}

void _printFamilies(Map<String, List<_FontFile>> families) {
  print(
    '🔍  Discovered ${families.length} font famil${families.length == 1 ? "y" : "ies"}:\n',
  );
  var i = 0;
  for (final entry in families.entries) {
    final weights = entry.value
        .map((f) => '${f.weight}${f.isItalic ? "i" : ""}')
        .join(', ');
    print(
      '  [$i] ${entry.key}  (${entry.value.length} file${entry.value.length == 1 ? "" : "s"}: $weights)',
    );
    i++;
  }
  print('');
}

// ── Interactive prompt ─────────────────────────────────────────────────────────

_FontOption? _promptFontOption(
  List<String> families,
  int num,
  List<_FontOption> existing,
) {
  print('── Option #$num ${'-' * (50 - 'Option #$num '.length)}');

  // Key
  final suggestedKey = num == 1 && families.isNotEmpty
      ? _toCamelCase(families.first).toLowerCase()
      : '';
  final key = _readString(
    'Key (unique id, e.g. "cairo")',
    defaultValue: suggestedKey,
    validate: (v) {
      if (v.isEmpty) return 'Key cannot be empty';
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v)) {
        return 'Use lowercase letters, digits, and underscores only';
      }
      if (existing.any((o) => o.key == v)) return 'Key "$v" already used';
      return null;
    },
  );

  // Arabic label
  final arabicLabel = _readString(
    'Arabic label (shown when locale=ar)',
    defaultValue: '',
  );

  // Latin label
  final latinLabel = _readString(
    'Latin label (shown when locale=en)',
    defaultValue: '',
  );

  // Arabic family
  print('\n  Which family for Arabic text?');
  _printFamilyMenu(families);
  final arabicIdx = _pickFamily(families, 'Arabic family');
  final arabicFamily = families[arabicIdx];

  // Latin family
  print('\n  Which family for Latin (non-Arabic) text?');
  print('  [s] Same as Arabic ($arabicFamily)');
  _printFamilyMenu(families);
  final latinFamily = _pickFamilyOrSame(families, arabicFamily, 'Latin family');

  return _FontOption(
    key: key,
    arabicLabel: arabicLabel,
    latinLabel: latinLabel,
    arabicFamily: arabicFamily,
    latinFamily: latinFamily,
  );
}

void _printFamilyMenu(List<String> families) {
  for (var i = 0; i < families.length; i++) {
    print('  [$i] ${families[i]}');
  }
}

int _pickFamily(List<String> families, String prompt) {
  while (true) {
    stdout.write('  → $prompt [0-${families.length - 1}]: ');
    final input = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
    final idx = int.tryParse(input);
    if (idx != null && idx >= 0 && idx < families.length) return idx;
    print('  ⚠  Enter a number between 0 and ${families.length - 1}.');
  }
}

String _pickFamilyOrSame(List<String> families, String sameAs, String prompt) {
  while (true) {
    stdout.write('  → $prompt [0-${families.length - 1} or s]: ');
    final input =
        stdin.readLineSync(encoding: utf8)?.trim().toLowerCase() ?? '';
    if (input == 's' || input == 'same' || input.isEmpty) return sameAs;
    final idx = int.tryParse(input);
    if (idx != null && idx >= 0 && idx < families.length) return families[idx];
    print('  ⚠  Enter a number or "s" for same.');
  }
}

String _readString(
  String prompt, {
  required String defaultValue,
  String? Function(String)? validate,
}) {
  while (true) {
    final hint = defaultValue.isNotEmpty ? ' [$defaultValue]' : '';
    stdout.write('  → $prompt$hint: ');
    var input = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
    if (input.isEmpty) input = defaultValue;

    if (validate != null) {
      final error = validate(input);
      if (error != null) {
        print('  ⚠  $error');
        continue;
      }
    }
    return input;
  }
}

bool _confirm(String prompt, {required bool defaultYes}) {
  final hint = defaultYes ? '[Y/n]' : '[y/N]';
  stdout.write('$prompt $hint: ');
  final input = stdin.readLineSync(encoding: utf8)?.trim().toLowerCase() ?? '';
  if (input.isEmpty) return defaultYes;
  return input == 'y' || input == 'yes';
}

// ── Default key selection ─────────────────────────────────────────────────────

String _pickDefault(List<_FontOption> options) {
  if (options.length == 1) return options.first.key;

  print('\n${'─' * 60}');
  print('⭐  Which option is the default (shown on first launch)?');
  for (var i = 0; i < options.length; i++) {
    print(
      '  [$i] ${options[i].key}  (${options[i].arabicLabel} / ${options[i].latinLabel})',
    );
  }

  while (true) {
    stdout.write('  → Default [0-${options.length - 1}] (default: 0): ');
    final input = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
    if (input.isEmpty) return options.first.key;
    final idx = int.tryParse(input);
    if (idx != null && idx >= 0 && idx < options.length) {
      return options[idx].key;
    }
    print('  ⚠  Enter a number between 0 and ${options.length - 1}.');
  }
}

void _syncPubspec(Map<String, List<_FontFile>> families) {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    _error('pubspec.yaml not found. Run from project root.');
    exit(1);
  }

  final now = DateTime.now().toIso8601String();
  final buf = StringBuffer()
    ..writeln(_pubspecStart)
    ..writeln('  # This section is automatically generated and managed.')
    ..writeln('  # DO NOT MODIFY MANUALLY!')
    ..writeln('  #')
    ..writeln('  # Generated on: $now')
    ..writeln('  # Run: dart run scripts/sync_fonts.dart to regenerate')
    ..writeln('  # ======================================================')
    ..writeln('  fonts:');

  for (final entry in families.entries) {
    buf.writeln('    - family: ${entry.key}');
    buf.writeln('      fonts:');
    for (final f in entry.value) {
      buf.writeln('        - asset: ${f.asset}');
      buf.writeln('          weight: ${f.weight}');
      if (f.isItalic) buf.writeln('          style: italic');
    }
  }

  buf.write(_pubspecEnd);

  var content = pubspec.readAsStringSync(encoding: utf8);
  final start = content.indexOf(_pubspecStart);
  final end = content.indexOf(_pubspecEnd);

  if (start != -1 && end != -1) {
    content = content.replaceRange(
      start,
      end + _pubspecEnd.length,
      buf.toString(),
    );
  } else {
    content += '\n${buf.toString()}\n';
  }

  pubspec.writeAsStringSync(content, encoding: utf8);
  print(
    '\n📦  pubspec.yaml updated (${families.length} famil${families.length == 1 ? "y" : "ies"})',
  );
}

// ── app_fonts.dart ────────────────────────────────────────────────────────────

void _syncAppFonts(List<_FontOption> options, String defaultKey) {
  final appFonts = File('lib/core/infra/config/app_fonts.dart');
  if (!appFonts.existsSync()) {
    _error('lib/core/infra/config/app_fonts.dart not found.');
    exit(1);
  }

  final buf = StringBuffer()
    ..writeln(_dartStart)
    ..writeln("  static const String defaultKey = '$defaultKey';")
    ..writeln()
    ..writeln('  static const List<AppFontOption> available = [');

  for (final opt in options) {
    final sameFamily = opt.arabicFamily == opt.latinFamily;
    buf
      ..writeln('    AppFontOption(')
      ..writeln("      key:          '${opt.key}',")
      ..writeln("      arabicLabel:  '${opt.arabicLabel}',")
      ..writeln("      latinLabel:   '${opt.latinLabel}',")
      ..writeln("      arabicFamily: '${opt.arabicFamily}',");

    if (sameFamily) {
      buf.writeln(
        "      latinFamily:  '${opt.latinFamily}', // same as Arabic",
      );
    } else {
      buf.writeln("      latinFamily:  '${opt.latinFamily}',");
    }

    buf.writeln('    ),');
  }

  buf
    ..writeln('  ];')
    ..write(_dartEnd);

  var content = appFonts.readAsStringSync(encoding: utf8);
  final start = content.indexOf(_dartStart);
  final end = content.indexOf(_dartEnd);

  if (start != -1 && end != -1) {
    content = content.replaceRange(
      start,
      end + _dartEnd.length,
      buf.toString(),
    );
  } else {
    _warn('Markers not found in app_fonts.dart — cannot update automatically.');
    print('  Add these markers manually around defaultKey and available:\n');
    print('  $_dartStart');
    print('  ...');
    print('  $_dartEnd');
    exit(1);
  }

  appFonts.writeAsStringSync(content, encoding: utf8);
  print(
    '🎨  app_fonts.dart updated (${options.length} option${options.length == 1 ? "" : "s"}, default: "$defaultKey")',
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _toCamelCase(String name) {
  if (name.isEmpty) return name;
  return name[0].toLowerCase() + name.substring(1);
}

void _warn(String msg) => print('\n⚠️   $msg');
void _error(String msg) {
  print('\n❌  $msg');
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _FontFile {
  const _FontFile({
    required this.asset,
    required this.weight,
    required this.isItalic,
  });
  final String asset;
  final int weight;
  final bool isItalic;
}

class _FontOption {
  const _FontOption({
    required this.key,
    required this.arabicLabel,
    required this.latinLabel,
    required this.arabicFamily,
    required this.latinFamily,
  });
  final String key;
  final String arabicLabel;
  final String latinLabel;
  final String arabicFamily;
  final String latinFamily;
}
