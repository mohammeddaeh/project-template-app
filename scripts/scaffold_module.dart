// ignore_for_file: avoid_print
/// مولّد موديول اختياري جديد — يكتب الأركان الثلاثة التي يفرضها CLAUDE.md
/// معاً دائماً لأي موديول تحت `lib/modules/`: علَم بـ`AppFeatures` · سطر
/// تسجيل بـ`ModulesBootstrap` · صفّ بجدول `10_ARCHITECTURE.md`.
///
/// **لماذا الثلاثة معاً بأمرٍ واحد**: نسيان أحد الأركان وقع تاريخياً بالقالب
/// (موديولٌ كامل الكود بلا سطر `ModulesBootstrap` حتى اكتُشف لاحقاً) — التوليد
/// الآلي يمنعه لأنه لا يترك خياراً بتخطّي ركن.
///
/// راجع `readme/41_ROADMAP.md` بند #03 للسياق الكامل.
///
/// تشغيل من جذر المشروع:
///   `dart run scripts/scaffold_module.dart <module_name>`
///   مثال: dart run scripts/scaffold_module.dart audit_log
library;

import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _die('الاستخدام: dart run scripts/scaffold_module.dart <module_name>\n'
        '  مثال: dart run scripts/scaffold_module.dart audit_log');
  }

  final module = _toSnakeCase(args.first);
  if (module.isEmpty || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(module)) {
    _die('اسم غير صالح: "${args.first}" — أحرف صغيرة وأرقام و"_" فقط، يبدأ بحرف.');
  }

  final vars = <String, String>{
    '__module__': module,
    '__Module__': _toPascalCase(module),
    '__moduleCamel__': _toCamelCase(module),
    '__MODULE_UPPER__': module.toUpperCase(),
  };

  final moduleDir = Directory('lib/modules/$module');
  if (moduleDir.existsSync()) {
    _die('lib/modules/$module/ موجود بالفعل — احذفه أولاً إن أردت إعادة التوليد.');
  }

  _header("🧩  scaffold_module — إنشاء \"${vars['__Module__']}Plugin\"");

  _section('📁  كتابة ملفّ المدخل');
  final pluginPath = 'lib/modules/$module/${module}_plugin.dart';
  File(pluginPath).parent.createSync(recursive: true);
  File(pluginPath).writeAsStringSync(_render(_pluginTemplate, vars));
  print('  ✓ $pluginPath');

  _section('🚩  الركن ١ — علَم AppFeatures');
  _appendFeatureFlag(vars);

  _section('🔗  الركن ٢ — تسجيل ModulesBootstrap');
  _appendBootstrapRegistration(vars);

  _section('📋  الركن ٣ — صفّ جدول 10_ARCHITECTURE.md');
  _appendArchitectureTableRow(vars);

  final healthy = await _runHealthChecks();

  _footer(
    healthy
        ? '✅  "${vars['__Module__']}Plugin" جاهز — التحليل والاختبارات نظيفة'
        : '⚠️   الملفات كُتبت لكن فحصاً واحداً على الأقل فشل — راجع الإخراج أعلاه',
  );

  print(
    'التالي:\n'
    '  1. سجّل تبعيات الموديول الفعلية بـ$pluginPath (مكان TODO).\n'
    '  2. راجع صفّ 10_ARCHITECTURE.md — عمود Packages لا يزال "TODO".\n'
    '  3. لو احتاج الموديول واجهة عرض: راجع نمط modules/multi_device/ (Widget عام\n'
    '     self-contained يملك cubit داخلياً — لا يستورده المستهلك أبداً).\n'
    '  4. أضف SETUP.md بخطوات التفعيل — كل موديول قائم يحمل واحداً.\n',
  );

  if (!healthy) exit(1);
}

// ── Templates ─────────────────────────────────────────────────────────────────

const _pluginTemplate = r'''
import 'package:get_it/get_it.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

/// وُلِّد بـ`scripts/scaffold_module.dart` — أضف تسجيلات DI الفعلية هنا.
///
/// ## التفعيل
/// 1. `AppFeatures.__moduleCamel__ = true`
/// 2. لا شيء آخر — `ModulesBootstrap.initializeAll()` ينادي هذا تلقائياً.
///
/// ## الإطفاء
/// اترك العلَم `false`. `initialize` يعود فوراً، ولا شيء يُسجَّل — **صفر أثر**،
/// نفس عقد كل موديول آخر بالقالب.
abstract final class __Module__Plugin {
  static bool _initialized = false;

  static const String _tag = '__MODULE_UPPER__';

  static Future<void> initialize(GetIt di) async {
    if (_initialized) return;
    if (!AppFeatures.__moduleCamel__) {
      LogService.debug(
        '__Module__Plugin disabled (AppFeatures.__moduleCamel__=false).',
        tag: _tag,
      );
      return;
    }

    LogService.debug('__Module__Plugin initializing...', tag: _tag);

    // TODO: سجّل تبعيات الموديول هنا، مثلاً:
    //   di.registerLazySingleton<SomeService>(() => SomeServiceImpl());

    _initialized = true;
    LogService.debug('__Module__Plugin ready.', tag: _tag);
  }

  /// لإعادة التهيئة بالاختبارات فقط.
  static void reset() => _initialized = false;
}
''';

// ── Shared-file edits ─────────────────────────────────────────────────────────

void _appendFeatureFlag(Map<String, String> vars) {
  final file = File('lib/core/platform/features/app_features.dart');
  const marker = '  static const inAppUpdates = false;';
  final addition =
      '$marker\n\n'
      '  /// وُلِّد بـ`scripts/scaffold_module.dart` — صِف الموديول هنا.\n'
      "  static const ${vars['__moduleCamel__']} = false;";
  final content = file.readAsStringSync();
  if (!content.contains(marker)) {
    _die('لم أجد نقطة الإدراج بـ${file.path} — راجعها يدوياً.');
  }
  file.writeAsStringSync(content.replaceFirst(marker, addition));
  print('  ✓ app_features.dart (AppFeatures.${vars['__moduleCamel__']} = false)');
}

void _appendBootstrapRegistration(Map<String, String> vars) {
  final file = File('lib/modules/modules_bootstrap.dart');
  var content = file.readAsStringSync();
  final module = vars['__module__']!;
  final featurePascal = vars['__Module__']!;
  final camel = vars['__moduleCamel__']!;

  const importMarker = "import 'package:app_template/modules/sync/sync_plugin.dart';";
  final newImport =
      "$importMarker\n"
      "import 'package:app_template/modules/$module/${module}_plugin.dart';";
  if (!content.contains(importMarker)) {
    _die('لم أجد نقطة إدراج الـimport بـ${file.path}.');
  }
  content = content.replaceFirst(importMarker, newImport);

  const registrationMarker = '''
    if (AppFeatures.dataTransfer) {
      await DataTransferPlugin.initialize(di);
    }
  }''';
  final newRegistration = '''
    if (AppFeatures.dataTransfer) {
      await DataTransferPlugin.initialize(di);
    }
    if (AppFeatures.$camel) {
      await ${featurePascal}Plugin.initialize(di);
    }
  }''';
  if (!content.contains(registrationMarker)) {
    _die('لم أجد نقطة تسجيل الموديول بـ${file.path}.');
  }
  content = content.replaceFirst(registrationMarker, newRegistration);

  file.writeAsStringSync(content);
  print('  ✓ modules_bootstrap.dart (${featurePascal}Plugin.initialize موصولٌ بعلَمه)');
}

void _appendArchitectureTableRow(Map<String, String> vars) {
  final file = File('readme/10_ARCHITECTURE.md');
  if (!file.existsSync()) {
    print('  ⚠️   readme/10_ARCHITECTURE.md غير موجود — أضف الصفّ يدوياً.');
    return;
  }
  const marker =
      '| `in_app_updates/` | `inAppUpdates` | ⬜ OFF | `InAppUpdatesModule.initialize(di)` بـ`ModulesBootstrap` + `AppUpdateGate` بالقشرة | in_app_update · package_info_plus · url_launcher |';
  final module = vars['__module__']!;
  final camel = vars['__moduleCamel__']!;
  final featurePascal = vars['__Module__']!;
  final newRowLine =
      '| `$module/` | `$camel` | ⬜ OFF | `${featurePascal}Plugin.initialize(di)` | TODO |';
  final newRow = '$marker\n$newRowLine';
  final content = file.readAsStringSync();
  if (!content.contains(marker)) {
    print('  ⚠️   لم أجد جدول الموديولات بالشكل المتوقَّع — أضف الصفّ يدوياً:');
    print('      $newRowLine');
    return;
  }
  file.writeAsStringSync(content.replaceFirst(marker, newRow));
  print('  ✓ readme/10_ARCHITECTURE.md (عمود Packages لا يزال TODO — عدّله يدوياً)');
}

// ── Health checks ─────────────────────────────────────────────────────────────

Future<bool> _runHealthChecks() async {
  _header('🩺  فحوصات ما بعد التوليد');
  var allPassed = true;
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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _render(String template, Map<String, String> vars) {
  var result = template;
  for (final entry in vars.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

String _toSnakeCase(String input) => input
    .trim()
    .replaceAll(RegExp(r'[\s-]+'), '_')
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m.group(1)}_${m.group(2)}',
    )
    .toLowerCase();

String _toPascalCase(String snake) => snake
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join();

String _toCamelCase(String snake) {
  final pascal = _toPascalCase(snake);
  return pascal.isEmpty ? pascal : pascal[0].toLowerCase() + pascal.substring(1);
}

void _header(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}');
void _footer(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}\n');
void _section(String msg) => print('\n▸ $msg');
void _die(String msg) {
  print('\n❌  $msg\n');
  exit(1);
}
