// ignore_for_file: avoid_print
/// معالج الإعداد التفاعلي الأول لمشروع جديد مبنيّ على هذا القالب.
///
/// يسأل عن هوية التطبيق (الاسم · Application ID) واختيار الوحدات الاختيارية
/// الأكثر كلفةً (تلك التي تحتاج تنسيقاً مع الباك أو حساباً خارجياً)، ثم يكتب
/// كل شيء دفعة واحدة، ويشغّل سلسلة تحقّق كاملة قبل أن يقول "جاهز".
///
/// **قاعدة صارمة يتّبعها هذا السكربت:** لا يحذف كوداً ولا تبعيةً أبداً — يبدّل
/// قيماً فقط (أعلام، هوية). فكل قرار هنا قابل للتراجع بسطر واحد لاحقاً، بحكم
/// أن كل موديول أصلاً بلا كلفة عند إطفائه — راجع `readme/41_ROADMAP.md` بند #01.
///
/// **خارج نطاق هذا الإصدار عمداً** (وليس سهواً):
///   - اسم حزمة Dart (`app_template` بـ`pubspec.yaml`) — يمسّ كل `import` بـ
///     `lib/` كاملاً، وCLAUDE.md نفسه يصفه بـ"مرّة واحدة أو أبداً". تغييرٌ
///     بهذا الحجم يستحق مراجعة يدوية، لا استبدالاً آلياً صامتاً.
///   - إعادة توليد لوحة الألوان الكاملة (`app_palette.dart`) من لون واحد —
///     اللوحة اليوم تدرّج يدوي مدروس (12+ درجة)، ولا أداة بالقالب تُنتج تدرّجاً
///     موثوقاً من لون واحد. يبقى تبديل الألوان خطوة يدوية موثَّقة بـ
///     `readme/01_SETUP.md`، متبوعةً بـ`flutter test test/color_contrast_test.dart`.
///
/// تشغيل من جذر المشروع مباشرة بعد الاستنساخ:
///   dart run scripts/setup_project.dart
library;

import 'dart:convert';
import 'dart:io';

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  _header('🚀  setup_project — إعداد مشروعك');

  final appName = _askRequired('اسم التطبيق (يظهر تحت الأيقونة)');
  final appId = _askAppId();

  final flags = await _askFeatureFlags();

  print('\n${'─' * 60}');
  print('  سيُطبَّق:');
  print('  اسم التطبيق      : $appName');
  print('  Application ID   : $appId');
  for (final entry in flags.entries) {
    print('  ${entry.key.padRight(17)}: ${entry.value ? 'true' : 'false'}');
  }
  print('─' * 60);
  if (!_askYesNo('متابعة الكتابة على القرص؟', defaultValue: true)) {
    print('\n⏹️   أُلغي — لم يتغيّر شيء.');
    exit(0);
  }

  _section('✍️   كتابة الهوية');
  _applyIdentity(appName: appName, appId: appId);

  _section('🚩  كتابة الأعلام');
  _applyFeatureFlags(flags);

  _section('📄  كتابة بيان المشروع');
  _writeManifest(appName: appName, appId: appId, flags: flags);

  await _stream('🍃  sync_flavors — تحديث ملفات أندرويد المشتقّة', 'dart', [
    'run',
    'scripts/sync_flavors.dart',
  ]);

  _printGotchas(flags);

  final healthy = await _runHealthChecks();

  _footer(
    healthy
        ? '✅  المشروع جاهز — التحليل والاختبارات نظيفة'
        : '⚠️   المشروع مكتوب لكن فحصاً واحداً على الأقل فشل — راجع الإخراج أعلاه',
  );

  print(
    'التالي: راجع readme/00_START_HERE.md لبدء أول feature فعلية.\n'
    'لم يُلمَس: اسم حزمة Dart (app_template) ولوحة الألوان — كلاهما خطوة يدوية\n'
    'موثَّقة بـreadme/01_SETUP.md، بقصد لا سهواً.\n',
  );

  if (!healthy) exit(1);
}

// ── Questions ────────────────────────────────────────────────────────────────

/// كل علَم هنا يحتاج شيئاً خارج مجرّد قيمة `bool` — تنسيقاً مع الباك، أو حساباً
/// خارجياً (Firebase)، أو التزاماً بنيوياً. الباقي (biometrics، clipboard،
/// haptics، صلاحيات المنصّة...) يبقى بقيمته الافتراضية بـ`app_features.dart`:
/// بلا كلفة خارجية، فسؤالٌ عنه بالإعداد الأول احتكاكٌ بلا فائدة —
/// راجع `readme/41_ROADMAP.md` بند #01 §تصنيف الخيارات.
const _flagQuestions = <String, String>{
  'accessControl':
      'الأدوار والصلاحيات (accessControl) — يحتاج تنسيقاً مع الباك',
  'dataTransfer': 'الاستيراد والتصدير (dataTransfer)',
  'offlineSync': 'المزامنة دون اتصال (offlineSync) — التزام بنيوي كبير',
  'multiDevice': 'الأجهزة والجلسات المتعددة (multiDevice)',
  'inAppUpdates': 'تنبيه تحديث التطبيق (inAppUpdates)',
  'crashReporting': 'تتبّع الأعطال (crashReporting) — يحتاج Firebase',
  'analytics': 'تحليلات الاستخدام (analytics) — يحتاج Firebase',
  'remoteConfig': 'قيم/أعلام عن بُعد (remoteConfig) — يحتاج Firebase',
};

/// القيم التي يضبطها كل نمط جاهز. غائبٌ عن هذا الجدول = يبقى على الافتراضي
/// الحالي بـ`app_features.dart` (لا يُسأل عنه ولا يُكتب).
const _presets = <String, Map<String, bool>>{
  'بسيط': {
    'accessControl': false,
    'dataTransfer': true,
    'offlineSync': false,
    'multiDevice': false,
    'inAppUpdates': false,
    'crashReporting': false,
    'analytics': false,
    'remoteConfig': false,
  },
  'مؤسسي': {
    'accessControl': true,
    'dataTransfer': true,
    'offlineSync': false,
    'multiDevice': true,
    'inAppUpdates': true,
    'crashReporting': true,
    'analytics': true,
    'remoteConfig': false,
  },
};

Future<Map<String, bool>> _askFeatureFlags() async {
  print('\n${'━' * 3} أي الوحدات الاختيارية تحتاجها؟ ${'━' * 3}');
  print('كل واحدة قابلة للتفعيل أو الإطفاء لاحقاً بسطر واحد — لا قرار نهائي هنا.\n');

  final choice = _askChoice('اختر نمطاً', ['بسيط', 'مؤسسي', 'مخصّص']);

  if (choice != 'مخصّص') {
    print('  → استُخدم نمط "$choice".');
    return Map<String, bool>.from(_presets[choice]!);
  }

  final result = <String, bool>{};
  for (final entry in _flagQuestions.entries) {
    result[entry.key] = _askYesNo(entry.value, defaultValue: false);
  }
  return result;
}

// ── Apply: identity ─────────────────────────────────────────────────────────

void _applyIdentity({required String appName, required String appId}) {
  // flavor_settings.json — مصدر الحقيقة الوحيد لهويّة كل flavor؛ sync_flavors.dart
  // يشتقّ منه strings.xml وlaunch.json وكتلة productFlavors بـbuild.gradle.kts.
  final settingsFile = File('flavor_settings.json');
  final settings =
      jsonDecode(settingsFile.readAsStringSync()) as Map<String, dynamic>;
  final flavors = settings['flavors'] as Map<String, dynamic>;
  (flavors['prod'] as Map<String, dynamic>)
    ..['displayName'] = appName
    ..['applicationId'] = appId;
  (flavors['dev'] as Map<String, dynamic>)
    ..['displayName'] = '$appName DEV'
    ..['applicationId'] = '$appId.dev';
  (flavors['staging'] as Map<String, dynamic>)
    ..['displayName'] = '$appName STAGING'
    ..['applicationId'] = '$appId.staging';
  settingsFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(settings)}\n',
  );
  print('  ✓ flavor_settings.json');

  // android/app/build.gradle.kts — namespace + applicationId الافتراضي
  // (المنفصلان عن كتلة productFlavors التي يعيد sync_flavors.dart توليدها).
  final gradle = File('android/app/build.gradle.kts');
  _replaceOrDie(
    gradle,
    'namespace = "com.example.app_template"',
    'namespace = "$appId"',
  );
  _replaceOrDie(
    gradle,
    'applicationId = "com.example.app_template"\n        // You can update',
    'applicationId = "$appId"\n        // You can update',
  );
  print('  ✓ android/app/build.gradle.kts');

  // iOS — الأخصّ أولاً (RunnerTests) قبل الأعمّ، وإلا التبديل العام يطابقها
  // أولاً فتصير النتيجة "$appId.RunnerTests.RunnerTests".
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  var content = pbxproj.readAsStringSync();
  final beforeTests = content;
  content = content.replaceAll(
    'PRODUCT_BUNDLE_IDENTIFIER = com.example.tempNew.RunnerTests;',
    'PRODUCT_BUNDLE_IDENTIFIER = $appId.RunnerTests;',
  );
  if (content == beforeTests) {
    _die('لم أجد PRODUCT_BUNDLE_IDENTIFIER (RunnerTests) بـproject.pbxproj');
  }
  final beforeMain = content;
  content = content.replaceAll(
    'PRODUCT_BUNDLE_IDENTIFIER = com.example.tempNew;',
    'PRODUCT_BUNDLE_IDENTIFIER = $appId;',
  );
  if (content == beforeMain) {
    _die('لم أجد PRODUCT_BUNDLE_IDENTIFIER (الرئيسي) بـproject.pbxproj');
  }
  pbxproj.writeAsStringSync(content);
  print('  ✓ ios/Runner.xcodeproj/project.pbxproj');

  final infoPlist = File('ios/Runner/Info.plist');
  final snakeName = appName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  _replaceOrDie(infoPlist, '<string>Temp New</string>', '<string>$appName</string>');
  _replaceOrDie(
    infoPlist,
    '<string>temp_new</string>',
    '<string>${snakeName.isEmpty ? 'app' : snakeName}</string>',
  );
  print('  ✓ ios/Runner/Info.plist');

  // pubspec.yaml — الوصف فقط. اسم الحزمة (`name:`) خارج النطاق عمداً.
  _replaceOrDie(
    File('pubspec.yaml'),
    'description: A new Flutter project.',
    'description: $appName.',
  );
  print('  ✓ pubspec.yaml (description)');
}

// ── Apply: feature flags ─────────────────────────────────────────────────────

void _applyFeatureFlags(Map<String, bool> flags) {
  final file = File('lib/core/platform/features/app_features.dart');
  var content = file.readAsStringSync();

  for (final entry in flags.entries) {
    final pattern = RegExp(
      'static const ${entry.key} = (true|false);',
    );
    if (!pattern.hasMatch(content)) {
      _die('لم أجد علَم "${entry.key}" بـapp_features.dart — هل تغيّر اسمه؟');
    }
    content = content.replaceFirst(
      pattern,
      'static const ${entry.key} = ${entry.value};',
    );
  }

  file.writeAsStringSync(content);
  print('  ✓ lib/core/platform/features/app_features.dart (${flags.length} علَماً)');
}

// ── Apply: manifest ──────────────────────────────────────────────────────────

void _writeManifest({
  required String appName,
  required String appId,
  required Map<String, bool> flags,
}) {
  final manifest = {
    'appName': appName,
    'applicationId': appId,
    'createdAt': DateTime.now().toIso8601String(),
    'templateVersion': _currentGitRef(),
    'features': flags,
  };
  File(
    '.template_manifest.json',
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  print('  ✓ .template_manifest.json');
}

/// أفضل محاولة فقط — مصدرٌ للتوثيق لا للمقارنة الدقيقة. مشروعٌ استُنسخ بلا
/// `.git` (مثلاً من أرشيف zip) يحصل على `"unknown"` بدل انهيار السكربت.
String _currentGitRef() {
  try {
    final result = Process.runSync('git', [
      'rev-parse',
      '--short',
      'HEAD',
    ]);
    if (result.exitCode == 0) return (result.stdout as String).trim();
  } catch (_) {
    // git غير متاح — لا مشكلة، الحقل وصفيّ لا حرج.
  }
  return 'unknown';
}

// ── Gotchas ──────────────────────────────────────────────────────────────────

const _gotchas = <String, String>{
  'accessControl':
      'يحتاج AUTHZ_ENABLED=true بالباك + إسناد دور — راجع readme/31_MODULE_PERMISSIONS.md',
  'dataTransfer':
      'يحتاج نصف الباك (backend_template/src/core/data-transfer/) — بدونه كل نداء 404',
  'offlineSync':
      'صفر عقود منفَّذة اليوم بالقالب — راجع lib/modules/sync/PLAN.md ب١٣/ب١٤ قبل الاعتماد عليه',
  'crashReporting':
      'لن يعمل بلا google-services.json (Android) و GoogleService-Info.plist (iOS)',
  'analytics':
      'لن يعمل بلا google-services.json (Android) و GoogleService-Info.plist (iOS)',
  'remoteConfig':
      'لن يعمل بلا google-services.json (Android) و GoogleService-Info.plist (iOS)',
  'inAppUpdates':
      'يحتاج نداءً يدوياً InAppUpdatesModule.checkAndPrompt(context) من شاشة مُركَّبة',
};

void _printGotchas(Map<String, bool> flags) {
  final active = flags.entries.where((e) => e.value && _gotchas.containsKey(e.key));
  if (active.isEmpty) return;
  print('\n⚠️   تذكيرات لما اخترته:');
  for (final entry in active) {
    print('   • ${entry.key}: ${_gotchas[entry.key]}');
  }
}

// ── Health checks ─────────────────────────────────────────────────────────────

Future<bool> _runHealthChecks() async {
  _header('🩺  فحوصات ما بعد الإعداد');
  var allPassed = true;

  allPassed &= await _check('📦  flutter pub get', 'flutter', ['pub', 'get']);
  allPassed &= await _check('🔍  dart analyze lib', 'dart', ['analyze', 'lib']);
  allPassed &= await _check('🧪  flutter test', 'flutter', ['test']);
  allPassed &= await _check(
    '🏗   check_structure',
    'dart',
    ['run', 'scripts/check_structure.dart'],
  );

  return allPassed;
}

Future<bool> _check(String label, String exe, List<String> args) async {
  _section(label);
  final process = await Process.start(exe, args, runInShell: true);
  await Future.wait([
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);
  final code = await process.exitCode;
  final ok = code == 0;
  print(ok ? '  ✅  نجح' : '  ❌  فشل (exit $code)');
  return ok;
}

// ── Prompt helpers ────────────────────────────────────────────────────────────

String _askRequired(String prompt) {
  while (true) {
    stdout.write('? $prompt: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isNotEmpty) return input;
    print('  ⚠️   لا يمكن أن يكون فارغاً.');
  }
}

final _appIdPattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

String _askAppId() {
  while (true) {
    stdout.write('? Application ID الأساسي (مثال: com.company.app): ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (_appIdPattern.hasMatch(input)) return input;
    print('  ⚠️   صيغة غير صالحة — أحرف صغيرة وأرقام و"." فقط، مقطعان على الأقل.');
  }
}

bool _askYesNo(String prompt, {required bool defaultValue}) {
  final hint = defaultValue ? 'Y/n' : 'y/N';
  while (true) {
    stdout.write('? $prompt ($hint): ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return defaultValue;
    if (input == 'y' || input == 'yes') return true;
    if (input == 'n' || input == 'no') return false;
    print('  ⚠️   أجب بـ y أو n.');
  }
}

String _askChoice(String prompt, List<String> options) {
  while (true) {
    print('? $prompt:');
    for (var i = 0; i < options.length; i++) {
      print('    ${i + 1}) ${options[i]}');
    }
    stdout.write('  اختر رقماً: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    final index = int.tryParse(input);
    if (index != null && index >= 1 && index <= options.length) {
      return options[index - 1];
    }
    print('  ⚠️   رقم غير صالح.');
  }
}

// ── File helpers ──────────────────────────────────────────────────────────────

void _replaceOrDie(File file, String from, String to) {
  final content = file.readAsStringSync();
  if (!content.contains(from)) {
    _die('لم أجد النصّ المتوقَّع بـ${file.path}:\n  "$from"');
  }
  file.writeAsStringSync(content.replaceFirst(from, to));
}

// ── Output helpers (بنمط scripts/gen_code.dart) ────────────────────────────────

Future<void> _stream(String label, String exe, List<String> args) async {
  _section(label);
  final process = await Process.start(exe, args, runInShell: true);
  await Future.wait([
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);
  final code = await process.exitCode;
  if (code != 0) _die('فشل الأمر (exit $code): $exe ${args.join(' ')}');
  print('');
}

void _header(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}');
void _footer(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}\n');
void _section(String msg) => print('\n▸ $msg');
void _die(String msg) {
  print('\n❌  $msg\n');
  exit(1);
}
