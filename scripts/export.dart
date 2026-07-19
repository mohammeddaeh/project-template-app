// ignore_for_file: avoid_print
/// تصدير APK مع إدارة الإصدار تلقائياً.
///
/// ┌─────────────────────────────────────────────────────────────────┐
/// │  dart run scripts/export.dart [options]                         │
/// ├──────────────┬──────────────────────┬────────────────────────── │
/// │ --flavor     │ dev|staging|prod     │ (افتراضي: dev)            │
/// │ --mode       │ debug|release        │ (افتراضي: debug)          │
/// │ --bump       │ build|patch|minor|   │ (افتراضي: build)          │
/// │              │ major                │                           │
/// │ --no-bump    │ —                    │ لا تغيير في الإصدار       │
/// │ --clean      │ —                    │ flutter clean أولاً       │
/// │ --no-codegen │ —                    │ تخطّى توليد الكود         │
/// └─────────────────────────────────────────────────────────────────┘
///
/// أنواع الـ bump:
///   build  →  1.2.3+5  →  1.2.3+6   (رقم البناء فقط — الافتراضي للتطوير)
///   patch  →  1.2.3+5  →  1.2.4+6   (bugfix)
///   minor  →  1.2.3+5  →  1.3.0+6   (feature جديدة)
///   major  →  1.2.3+5  →  2.0.0+6   (إعادة هيكلة)
///
/// بعد البناء يكتب البيانات في .dart_tool/last_build.json (مُتجاهَل git).
/// تقرأه scripts/install.dart لمعرفة مسار APK ورقم الحزمة.
library;

import 'dart:convert';
import 'dart:io';

// ── Constants ─────────────────────────────────────────────────────────────────

const _settingsFile  = 'flavor_settings.json';
const _pubspecFile   = 'pubspec.yaml';
const _lastBuildFile = '.dart_tool/last_build.json';

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  // ── Parse args
  final flavor    = _arg(args, '--flavor',  'dev');
  final mode      = _arg(args, '--mode',    'debug');
  final bump      = _arg(args, '--bump',    'build');
  final noBump    = args.contains('--no-bump');
  final clean     = args.contains('--clean');
  final noCodegen = args.contains('--no-codegen');

  _validateFlavor(flavor);
  _validateMode(mode);
  if (!noBump) _validateBump(bump);

  // ── Load flavor settings
  final settings  = _loadSettings();
  final packageId = _packageId(settings, flavor);

  _header('🏗   export.dart');
  print('  flavor   : $flavor  ($packageId)');
  print('  mode     : $mode');
  print('  bump     : ${noBump ? "off (--no-bump)" : bump}');
  print('  clean    : $clean');
  print('  codegen  : ${!noCodegen}');

  // ──────────────────────────────────────────────────────────────────
  // الخطوة 1: flutter clean (اختياري)
  // ──────────────────────────────────────────────────────────────────
  if (clean) {
    _section('🧹  Flutter clean');
    await _stream('flutter', ['clean']);
    await _stream('flutter', ['pub', 'get']);
  }

  // ──────────────────────────────────────────────────────────────────
  // الخطوة 2: رفع الإصدار في pubspec.yaml
  // ──────────────────────────────────────────────────────────────────
  _section('🏷   Version bump');
  if (noBump) {
    print('  skipped (--no-bump)');
  } else {
    _bumpVersion(bump);
  }
  final version = _readVersion();
  print('  current  : $version');

  // ──────────────────────────────────────────────────────────────────
  // الخطوة 2.5: تحديث اسم التطبيق بالإصدار الجديد
  // ──────────────────────────────────────────────────────────────────
  _section('📛  App name');
  _updateAppName(flavor, version, settings);

  // ──────────────────────────────────────────────────────────────────
  // الخطوة 3: توليد الكود
  // ──────────────────────────────────────────────────────────────────
  if (!noCodegen) {
    _section('⚙️   Code generation');
    await _stream('dart', ['run', 'scripts/codegen.dart']);
  }

  // ──────────────────────────────────────────────────────────────────
  // الخطوة 4: flutter build apk
  // ──────────────────────────────────────────────────────────────────
  // التحقق من وجود ملف البيئة قبل البناء
  final envFile = '.env.$flavor.json';
  if (!File(envFile).existsSync()) {
    _die('ملف البيئة غير موجود: $envFile\n'
        '    أنشئه أولاً بـ BASE_URL والإعدادات اللازمة.');
  }

  _section('🔨  Flutter build apk  [$flavor · $mode]');
  await _stream('flutter', [
    'build', 'apk',
    '--flavor', flavor,
    '--$mode',
    '--dart-define=FLAVOR=$flavor',
    '--dart-define-from-file=$envFile',
  ]);

  // ──────────────────────────────────────────────────────────────────
  // نتيجة البناء
  // ──────────────────────────────────────────────────────────────────
  final rawApkPath = 'build/app/outputs/flutter-apk/app-$flavor-$mode.apk';
  final rawApkFile = File(rawApkPath);

  if (!rawApkFile.existsSync()) {
    _die('APK غير موجود في المسار المتوقع:\n    $rawApkPath');
  }

  // إعادة التسمية: {displayName}-{mode}-{version}.apk
  final flavors     = settings['flavors'] as Map<String, dynamic>;
  final displayName = (flavors[flavor] as Map<String, dynamic>)['displayName'] as String? ?? flavor;
  final versionTag  = version.replaceAll('+', '_');
  final apkDir      = rawApkFile.parent.path;
  final apkPath     = '$apkDir/$displayName-$mode-$versionTag.apk';
  rawApkFile.renameSync(apkPath);

  final sizeMb = (File(apkPath).lengthSync() / (1024 * 1024));

  // اكتب بيانات البناء
  Directory('.dart_tool').createSync(recursive: true);
  File(_lastBuildFile).writeAsStringSync(jsonEncode({
    'apkPath'  : apkPath,
    'packageId': packageId,
    'version'  : version,
    'flavor'   : flavor,
    'mode'     : mode,
    'builtAt'  : DateTime.now().toIso8601String(),
  }));

  _footer('''✅  Build complete
  APK     : $apkPath
  Size    : ${sizeMb.toStringAsFixed(1)} MB
  Package : $packageId
  Version : $version''');
}

// ── Version management ────────────────────────────────────────────────────────

/// يقرأ version من pubspec.yaml كما هو.
String _readVersion() {
  final content = File(_pubspecFile).readAsStringSync();
  final match   = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);
  if (match == null) _die('لم يُعثر على "version:" في $_pubspecFile');
  return match.group(1)!.trim();
}

/// يعدّل version في pubspec.yaml حسب نوع الـ bump.
///
/// الصيغة المقبولة: MAJOR.MINOR.PATCH[+BUILD]
/// إذا لم يكن +BUILD موجوداً (مثل "1.0.0") يُعامَل كـ +0.
void _bumpVersion(String bump) {
  final content = File(_pubspecFile).readAsStringSync();

  final match = RegExp(
    r'^(version:\s*)(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?',
    multiLine: true,
  ).firstMatch(content);

  if (match == null) {
    _die('لا يمكن قراءة رقم الإصدار من $_pubspecFile\n'
        'التنسيق المتوقع: version: 1.2.3+45');
  }

  var major = int.parse(match.group(2)!);
  var minor = int.parse(match.group(3)!);
  var patch = int.parse(match.group(4)!);
  var build = int.parse(match.group(5) ?? '0'); // بدون +N → يبدأ من 0

  final oldLabel = '$major.$minor.$patch${match.group(5) != null ? "+$build" : ""}';

  // رفع versionCode دائماً (منع INSTALL_FAILED_VERSION_DOWNGRADE)
  build++;

  switch (bump) {
    case 'major': major++; minor = 0; patch = 0;
    case 'minor': minor++; patch = 0;
    case 'patch': patch++;
    case 'build': break; // versionCode فقط — رُفع بالفعل
  }

  final newVersion = '$major.$minor.$patch+$build';

  // استبدال السطر كاملاً بالإصدار الجديد
  final newContent = content.replaceFirst(
    RegExp(r'^version:\s*\S+', multiLine: true),
    'version: $newVersion',
  );

  File(_pubspecFile).writeAsStringSync(newContent);
  print('  $oldLabel  →  $newVersion');
}

// ── App name update ───────────────────────────────────────────────────────────

/// يُحدِّث app_name في strings.xml الخاص بالـ flavor بإضافة رقم الإصدار.
/// يعمل فقط إذا كان showVersion: true في flavor_settings.json.
/// يستخدم MAJOR.MINOR.PATCH فقط (بدون +buildNumber).
void _updateAppName(String flavor, String version, Map<String, dynamic> settings) {
  final flavors = settings['flavors'] as Map<String, dynamic>;
  final cfg     = flavors[flavor] as Map<String, dynamic>? ?? {};

  final showVersion = cfg['showVersion'] as bool? ?? false;
  final baseName    = cfg['displayName'] as String? ?? flavor;

  if (!showVersion) {
    print('  skipped (showVersion: false)  →  $baseName');
    return;
  }

  final newName = '$baseName $version';

  final stringsFile = File('android/app/src/$flavor/res/values/strings.xml');
  if (!stringsFile.existsSync()) {
    print('  ⚠️  strings.xml غير موجود للـ flavor "$flavor" — تخطّى');
    return;
  }

  final updated = stringsFile.readAsStringSync().replaceFirst(
    RegExp(r'<string name="app_name">[^<]*</string>'),
    '<string name="app_name">$newName</string>',
  );

  stringsFile.writeAsStringSync(updated);
  print('  app_name  →  $newName');
}

// ── Flavor settings ───────────────────────────────────────────────────────────

Map<String, dynamic> _loadSettings() {
  final file = File(_settingsFile);
  if (!file.existsSync()) {
    _die('$_settingsFile غير موجود. شغّل من جذر المشروع.');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

String _packageId(Map<String, dynamic> settings, String flavor) {
  final flavors = settings['flavors'] as Map<String, dynamic>;
  final cfg     = flavors[flavor] as Map<String, dynamic>?;
  if (cfg == null) {
    _die('الـ flavor "$flavor" غير موجود في $_settingsFile');
  }
  return cfg['applicationId'] as String;
}

// ── Process helpers ───────────────────────────────────────────────────────────

/// يشغّل أمراً مع إخراج حيّ (streaming) — يفشل إذا كان exit code ≠ 0.
Future<void> _stream(String exe, List<String> args) async {
  final process = await Process.start(exe, args, runInShell: true);
  // addStream لا يُغلق stdout/stderr — pipe() تُغلقهما وتقطع كل الخرج اللاحق
  await Future.wait([
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);
  final code = await process.exitCode;
  if (code != 0) _die('فشل الأمر (exit $code): $exe ${args.join(' ')}');
}

// ── Validation ────────────────────────────────────────────────────────────────

void _validateFlavor(String f) {
  if (!{'dev', 'staging', 'prod'}.contains(f)) {
    _die('flavor غير معروف: "$f"\nالقيم المسموح بها: dev | staging | prod');
  }
}

void _validateMode(String m) {
  if (!{'debug', 'release'}.contains(m)) {
    _die('mode غير معروف: "$m"\nالقيم المسموح بها: debug | release');
  }
}

void _validateBump(String b) {
  if (!{'build', 'patch', 'minor', 'major'}.contains(b)) {
    _die('bump غير معروف: "$b"\nالقيم المسموح بها: build | patch | minor | major');
  }
}

// ── Print helpers ─────────────────────────────────────────────────────────────

void _header(String msg)  => print('\n${'─' * 60}\n  $msg\n${'─' * 60}');
void _footer(String msg)  => print('\n${'─' * 60}\n  $msg\n${'─' * 60}\n');
void _section(String msg) => print('\n▸ $msg');
Never _die(String msg)    { print('\n❌  $msg\n'); exit(1); }

// ── Arg parser ────────────────────────────────────────────────────────────────

String _arg(List<String> args, String flag, String fallback) {
  final i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return fallback;
  return args[i + 1];
}
