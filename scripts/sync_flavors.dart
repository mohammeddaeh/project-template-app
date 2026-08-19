// ignore_for_file: avoid_print
/// يقرأ flavor_settings.json ويُحدِّث تلقائياً:
///   1. .env.{f}.json                            — ملف بيئة لكل flavor من .env.example.json (لا يلمس قيمة موجودة)
///   2. android/app/build.gradle.kts             — productFlavors + applicationId لكل flavor (بين علامات BEGIN/END FLAVORS)
///   3. android/app/src/{f}/res/values/strings.xml — اسم التطبيق لكل flavor
///   4. flutter_launcher_icons-{f}.yaml          — ملفات إعداد الأيقونات
///   5. يُشغِّل flutter_launcher_icons لكل flavor
///   6. .vscode/launch.json                      — إعدادات تشغيل VSCode
///
/// تشغيل من جذر المشروع:
///   dart run scripts/sync_flavors.dart           — إعداد الـ flavors
///   dart run scripts/sync_flavors.dart --reset   — إزالة كل شيء تابع للـ flavors
library;

import 'dart:convert';
import 'dart:io';

// ── Constants ─────────────────────────────────────────────────────────────────

const _settingsFile = 'flavor_settings.json';
const _envExampleFile = '.env.example.json';

/// يُستخدم فقط لو غاب `.env.example.json` أو كان تالفاً.
const _envFallback = <String, dynamic>{'BASE_URL': 'https://api.example.com'};

// ── Entry point ───────────────────────────────────────────────────────────────

void main(List<String> args) async {
  if (args.contains('--reset')) {
    _reset();
    return;
  }

  print('\n🚀  sync_flavors — starting...\n');

  // 1. Load & validate flavor_settings.json
  final root = findFlutterRoot();
  final settings = _loadSettings(root);
  final flavors = settings['flavors'] as Map<String, dynamic>;

  print('📋  Flavors found: ${flavors.keys.join(', ')}\n');

  // 2. Create any missing .env.{flavor}.json (git-ignored — never reaches a clone)
  final envNeedsEditing = _ensureEnvFiles(root, flavors);

  // 3. Validate icon files exist before doing any work
  _validateIcons(root, flavors);

  // 4. Inject productFlavors into android/app/build.gradle.kts
  _updateBuildGradle(root, flavors);

  // 5. Create per-flavor strings.xml (app name — most reliable approach)
  _updateAndroidStrings(root, flavors);

  // 6. Generate flutter_launcher_icons-{flavor}.yaml files
  _generateIconYamls(root, flavors);

  // 7. Run flutter_launcher_icons for each flavor
  await _runIconGeneration(root, flavors);

  // 8. Generate .vscode/launch.json
  _generateLaunchJson(root, flavors);

  print('\n✅  sync_flavors done.\n');
  print('─────────────────────────────────────────────────────────────────');
  if (envNeedsEditing.isNotEmpty) {
    print('  ⚠️  Set the real API URL in these files before building:');
    for (final name in envNeedsEditing) {
      print('      $name');
    }
    print('');
  }
  print('  Next: clean & rebuild the app to see the new icons.');
  print('  flutter clean && flutter pub get');
  print('─────────────────────────────────────────────────────────────────\n');
}

Directory findFlutterRoot() {
  var dir = Directory.current;

  // 1. search upward
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir;
    }

    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  // 2. search downward (important for monorepo)
  final candidates = Directory.current
      .listSync(recursive: true)
      .whereType<Directory>()
      .where((d) => File('${d.path}/pubspec.yaml').existsSync())
      .toList();

  if (candidates.isNotEmpty) {
    print('📦 Found Flutter project at: ${candidates.first.path}');
    return candidates.first;
  }

  throw Exception('Flutter project root not found');
}
// ── Step 1 — load settings ────────────────────────────────────────────────────

Map<String, dynamic> _loadSettings(Directory root) {
  final file = File('${root.path}/$_settingsFile');

  if (!file.existsSync()) {
    _error('$_settingsFile not found. Run from project root.');
    exit(1);
  }

  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

// ── Step 2 — ensure .env.{flavor}.json ────────────────────────────────────────

/// ملفات `.env.{flavor}.json` مُتجاهَلة في git (تحمل روابط API حقيقية)، فمن
/// يستنسخ المشروع لا تصله — وبدونها ينكسر `flutter run` عند
/// `--dart-define-from-file`. هذه الخطوة تُنشئ الناقص منها بالشكل الصحيح من
/// `.env.example.json`، وتُكمل أي مفتاح جديد في ملف قديم.
///
/// **لا تُعدَّل قيمة موجودة أبداً** — الموجود يبقى كما هو.
/// تُرجع أسماء الملفات التي ما زالت تحتاج تعبئة يدوية.
List<String> _ensureEnvFiles(Directory root, Map<String, dynamic> flavors) {
  final template = _loadEnvTemplate(root);
  final needsEditing = <String>[];

  for (final flavor in flavors.keys) {
    final name = '.env.$flavor.json';
    final file = File('${root.path}/$name');

    // (أ) غير موجود — يُنشأ من القالب
    if (!file.existsSync()) {
      _writeJson(file, template);
      print('🆕  $name created from $_envExampleFile — fill in the real URL');
      needsEditing.add(name);
      continue;
    }

    final current = _readJsonOrNull(file);
    if (current == null) {
      _error('$name is not valid JSON — left untouched. Fix it manually.');
      needsEditing.add(name);
      continue;
    }

    // (ب) موجود لكن ينقصه مفتاح أضافه القالب لاحقاً
    final missing = template.keys.where((k) => !current.containsKey(k));
    if (missing.isNotEmpty) {
      final merged = <String, dynamic>{
        for (final k in template.keys) k: current[k] ?? template[k],
        ...current, // مفاتيح إضافية خاصة بالمشروع تبقى كما هي
      };
      _writeJson(file, merged);
      print('➕  $name — added missing key(s): ${missing.join(', ')}');
      needsEditing.add(name);
      continue;
    }

    // (ج) موجود وكامل — لكن هل ما زال يحمل قيمة المثال؟
    // قيمة فارغة في القالب = مفتاح اختياري، لا placeholder — لا تُنبِّه عليها.
    final placeholders = template.entries
        .where((e) => e.value != '' && current[e.key] == e.value)
        .map((e) => e.key);
    if (placeholders.isNotEmpty) {
      _warn('$name still holds example value(s): ${placeholders.join(', ')}');
      needsEditing.add(name);
    } else {
      print('🔐  $name ok');
    }
  }

  return needsEditing;
}

Map<String, dynamic> _loadEnvTemplate(Directory root) {
  final example = File('${root.path}/$_envExampleFile');
  if (!example.existsSync()) {
    _warn('$_envExampleFile not found — using built-in defaults.');
    return Map<String, dynamic>.of(_envFallback);
  }
  final parsed = _readJsonOrNull(example);
  if (parsed == null || parsed.isEmpty) {
    _warn('$_envExampleFile is empty or invalid — using built-in defaults.');
    return Map<String, dynamic>.of(_envFallback);
  }
  return parsed;
}

Map<String, dynamic>? _readJsonOrNull(File file) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

void _writeJson(File file, Map<String, dynamic> data) {
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
}

// ── Step 3 — validate icons ───────────────────────────────────────────────────

void _validateIcons(Directory root, Map<String, dynamic> flavors) {
  var missing = false;
  for (final entry in flavors.entries) {
    final cfg = entry.value as Map<String, dynamic>;
    final path = cfg['iconPath'] as String;
    if (!File('${root.path}/$path').existsSync()) {
      _warn('Icon not found for "${entry.key}": $path');
      missing = true;
    }
  }
  if (missing) {
    print('''
⚠️  One or more icon files are missing.
    Place 1024×1024 PNG files at the paths listed in flavor_settings.json,
    then re-run this script.
    Icon generation will be skipped for missing flavors.
''');
  }
}

// ── Step 4 — inject productFlavors into build.gradle.kts ─────────────────────

void _updateBuildGradle(Directory root, Map<String, dynamic> flavors) {
  final file = File('${root.path}/android/app/build.gradle.kts');
  if (!file.existsSync()) {
    _error('${root.path}/android/app/build.gradle.kts not found.');
    return;
  }

  final buf = StringBuffer();
  buf.writeln(
    '    // BEGIN FLAVORS — auto-generated by: dart run scripts/sync_flavors.dart',
  );
  buf.writeln('    flavorDimensions += "app"');
  buf.writeln('    productFlavors {');
  for (final entry in flavors.entries) {
    final name = entry.key;
    final id = (entry.value as Map<String, dynamic>)['applicationId'] as String;
    buf.writeln('        create("$name") {');
    buf.writeln('            dimension = "app"');
    buf.writeln('            applicationId = "$id"');
    buf.writeln('        }');
  }
  buf.writeln('    }');
  buf.write('    // END FLAVORS');

  final content = file.readAsStringSync();
  final replaced = _replaceBetweenMarkers(content, buf.toString());
  file.writeAsStringSync(replaced);
  print('🤖  Updated productFlavors in android/app/build.gradle.kts');
}

String _replaceBetweenMarkers(String content, String newBlock) {
  const begin = '// BEGIN FLAVORS';
  const end = '// END FLAVORS';
  final iBegin = content.indexOf(begin);
  final iEnd = content.indexOf(end);

  // Markers found — replace between them (normal case)
  if (iBegin != -1 && iEnd != -1) {
    return content.substring(0, iBegin) +
        newBlock +
        content.substring(iEnd + end.length);
  }

  // Markers missing (e.g. after --reset) — auto-insert before android {} closing brace
  final flutterStart = content.indexOf('\nflutter {');
  if (flutterStart == -1) {
    _warn('Cannot find `flutter {` in build.gradle.kts — flavors not added.');
    return content;
  }
  final androidClose = content.lastIndexOf('}', flutterStart);
  if (androidClose == -1) {
    _warn('Cannot find android {} closing brace — flavors not added.');
    return content;
  }
  print('🔧  Markers missing — auto-inserting productFlavors block.');
  return '${content.substring(0, androidClose)}\n\n$newBlock\n${content.substring(androidClose)}';
}

// ── Step 5 — per-flavor strings.xml ──────────────────────────────────────────

String _loadPubspecVersion() {
  final file = File('pubspec.yaml');

  if (!file.existsSync()) {
    _warn('pubspec.yaml not found — version will be skipped.');
    return '';
  }

  final content = file.readAsStringSync();

  final match = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(content);

  if (match == null) return '';

  final fullVersion = match.group(1)!;

  // غالباً بيكون: 1.0.0+1 → بدنا فقط 1.0.0
  return fullVersion;
}

void _updateAndroidStrings(Directory root, Map<String, dynamic> flavors) {
  final pubspec = _loadPubspecVersion();

  for (final entry in flavors.entries) {
    final flavor = entry.key;
    final cfg = entry.value as Map<String, dynamic>;

    final baseName = cfg['displayName'] as String;
    final showVersion = cfg['showVersion'] as bool? ?? false;

    final finalName = showVersion ? '$baseName v$pubspec' : baseName;

    final dir = Directory('android/app/src/$flavor/res/values');
    dir.createSync(recursive: true);

    File('${dir.path}/strings.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<resources>\n'
      '    <string name="app_name">$finalName</string>\n'
      '</resources>\n',
    );

    print('📝  strings.xml [$flavor] → "$finalName"');
  }
}

// ── Step 6 — flutter_launcher_icons yaml ─────────────────────────────────────

void _generateIconYamls(Directory root, Map<String, dynamic> flavors) {
  for (final entry in flavors.entries) {
    final flavor = entry.key;
    final cfg = entry.value as Map<String, dynamic>;
    final icon = cfg['iconPath'] as String;
    final bg = cfg['adaptiveIconBackground'] as String? ?? '#FFFFFF';

    if (!File('${root.path}/$icon').existsSync()) {
      return; // already warned above
    }

    final yaml =
        '''flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  remove_alpha_ios: true
  image_path: "$icon"
  min_sdk_android: 21
  adaptive_icon_background: "$bg"
  adaptive_icon_foreground: "$icon" 
''';

    File(
      '${root.path}/flutter_launcher_icons-$flavor.yaml',
    ).writeAsStringSync(yaml);
    print('📄  flutter_launcher_icons-$flavor.yaml generated');
  }
}

// ── Step 7 — run flutter_launcher_icons ──────────────────────────────────────

Future<void> _runIconGeneration(
  Directory root,
  Map<String, dynamic> flavors,
) async {
  print('');
  for (final flavor in flavors.keys) {
    final yamlFile = '${root.path}/flutter_launcher_icons-$flavor.yaml';
    if (!File(yamlFile).existsSync()) {
      _warn('Skipping icon generation for $flavor — yaml not found.');
      continue;
    }

    print('🖼   Generating icons for "$flavor"...');
    final result = await Process.run(
      'dart',
      ['run', 'flutter_launcher_icons', '-f', yamlFile],
      workingDirectory: root.path, // ✅ الحل
      runInShell: true,
    );

    if (result.exitCode == 0) {
      print('✅  Icons for "$flavor" done.');
    } else {
      _error('Icon generation failed for "$flavor":\n${result.stderr}');
    }
  }
}

// ── Step 8 — .vscode/launch.json ─────────────────────────────────────────────

void _generateLaunchJson(Directory root, Map<String, dynamic> flavors) {
  final configs = <Map<String, dynamic>>[];

  for (final flavor in flavors.keys) {
    configs.add({
      'name': '${flavor.toUpperCase()} · Debug',
      'request': 'launch',
      'type': 'dart',
      'flutterMode': 'debug',
      'program': 'lib/main.dart',
      'args': [
        '--flavor',
        flavor,
        '--dart-define=FLAVOR=$flavor',
        '--dart-define-from-file=.env.$flavor.json',
      ],
    });
  }

  Directory('${root.path}/.vscode').createSync(recursive: true);
  File('${root.path}/.vscode/launch.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'version': '0.2.0', 'configurations': configs})}\n',
  );
  print('🚀  Generated .vscode/launch.json (${configs.length} configs)');
}

// ── Reset ─────────────────────────────────────────────────────────────────────

void _reset() {
  final root = findFlutterRoot();
  print('\n🧹  sync_flavors --reset — removing all flavor artifacts...\n');

  // 1. Per-flavor source directories (strings.xml, icons…)
  for (final flavor in ['dev', 'staging', 'prod']) {
    _deleteDir('${root.path}/android/app/src/$flavor');
    _deleteFile('${root.path}/flutter_launcher_icons-$flavor.yaml');
  }

  // 2. Clear productFlavors block from build.gradle.kts (between markers)
  final buildFile = File('${root.path}/android/app/build.gradle.kts');
  if (buildFile.existsSync()) {
    const begin = '// BEGIN FLAVORS';
    const end = '// END FLAVORS';
    final content = buildFile.readAsStringSync();
    final iBegin = content.indexOf(begin);
    final iEnd = content.indexOf(end);
    if (iBegin != -1 && iEnd != -1) {
      final cleaned =
          '${content.substring(0, iBegin).trimRight()}\n${content.substring(iEnd + end.length).trimLeft()}';
      buildFile.writeAsStringSync(cleaned);
      print('✏️   Cleared productFlavors from android/app/build.gradle.kts');
    }
  }

  // 3. .vscode/launch.json
  _deleteFile('${root.path}/.vscode/launch.json');

  print('\n✅  Reset done. Project is back to plain Flutter (no flavors).');
  print('   Run: flutter clean && flutter pub get\n');
}

void _deleteFile(String path) {
  final f = File(path);
  if (f.existsSync()) {
    f.deleteSync();
    print('🗑   Deleted $path');
  }
}

void _deleteDir(String path) {
  final d = Directory(path);
  if (d.existsSync()) {
    d.deleteSync(recursive: true);
    print('🗑   Deleted $path/');
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _warn(String msg) => print('⚠️   $msg');
void _error(String msg) => print('❌   $msg');
