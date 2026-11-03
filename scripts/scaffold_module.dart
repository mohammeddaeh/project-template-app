// ignore_for_file: avoid_print
/// مولّد موديول اختياري جديد — يكتب الأركان الثلاثة التي يفرضها CLAUDE.md (R29)
/// معاً دائماً لأي موديول تحت `lib/modules/`: علَم بـ`AppFeatures` · سطر
/// تسجيل بـ`ModulesBootstrap` · صفّ بالجدول الواحد `readme/modules/30_MODULES.md`.
///
/// **لماذا الثلاثة معاً بأمرٍ واحد**: ركنٌ منسيّ لا يراه المصرِّف ولا
/// الاختبارات — موديولٌ بلا سطر `ModulesBootstrap` يُصرَّف ولا يعمل، وموديولٌ
/// بلا صفّ بالجدول لا يعرفه القارئ الجديد. التوليد الآلي لا يترك خياراً بتخطّي ركن.
///
/// تشغيل من جذر المشروع:
///   `dart run scripts/scaffold_module.dart <module_name>`
///   مثال: dart run scripts/scaffold_module.dart audit_log
library;

import 'dart:io';
import 'src/cli.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    die(
      'الاستخدام: dart run scripts/scaffold_module.dart <module_name>\n'
      '  مثال: dart run scripts/scaffold_module.dart audit_log',
    );
  }

  final module = toSnakeCase(args.first);
  if (module.isEmpty || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(module)) {
    die(
      'اسم غير صالح: "${args.first}" — أحرف صغيرة وأرقام و"_" فقط، يبدأ بحرف.',
    );
  }

  final vars = <String, String>{
    '__module__': module,
    '__Module__': toPascalCase(module),
    '__moduleCamel__': toCamelCase(module),
    '__MODULE_UPPER__': module.toUpperCase(),
  };

  final moduleDir = Directory('lib/modules/$module');
  if (moduleDir.existsSync()) {
    die(
      'lib/modules/$module/ موجود بالفعل — احذفه أولاً إن أردت إعادة التوليد.',
    );
  }

  header("🧩  scaffold_module — إنشاء \"${vars['__Module__']}Plugin\"");

  section('📁  كتابة ملفّ المدخل');
  final pluginPath = 'lib/modules/$module/${module}_plugin.dart';
  File(pluginPath).parent.createSync(recursive: true);
  File(pluginPath).writeAsStringSync(_render(_pluginTemplate, vars));
  print('  ✓ $pluginPath');

  section('🚩  الركن ١ — علَم AppFeatures');
  _appendFeatureFlag(vars);

  section('🔗  الركن ٢ — تسجيل ModulesBootstrap');
  _appendBootstrapRegistration(vars);

  section('📋  الركن ٣ — صفّ بالجدول readme/modules/30_MODULES.md');
  _appendModulesTableRow(vars);

  section('🔎  إشارة الجرد — scripts/src/port_signals.dart');
  _appendPortSignalTodo(vars);

  final healthy = await _runHealthChecks();

  footer(
    healthy
        ? '✅  "${vars['__Module__']}Plugin" جاهز — التحليل والاختبارات نظيفة'
        : '⚠️   الملفات كُتبت لكن فحصاً واحداً على الأقل فشل — راجع الإخراج أعلاه',
  );

  print(
    'التالي:\n'
    '  1. سجّل تبعيات الموديول الفعلية بـ$pluginPath (مكان TODO).\n'
    '  2. أكمل صفّه بـreadme/modules/30_MODULES.md — الوصف وما يحتاجه خارج التطبيق.\n'
    '  3. لو احتاج الموديول واجهة عرض: راجع نمط modules/multi_device/ (Widget عام\n'
    '     self-contained يملك cubit داخلياً — لا يستورده المستهلك أبداً).\n'
    '  4. أضف SETUP.md بخطوات التفعيل — كل موديول قائم يحمل واحداً.\n'
    '  5. بـscripts/src/port_signals.dart: استبدل استثناءه TODO بإشارةٍ تكشف\n'
    '     قدرته بتطبيقٍ قديم (أو بسببٍ حقيقيٍّ لغيابها).\n',
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
/// 2. لا شيء آخر — `ModulesBootstrap` ينادي هذا تلقائياً.
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
    die('لم أجد نقطة الإدراج بـ${file.path} — راجعها يدوياً.');
  }
  file.writeAsStringSync(content.replaceFirst(marker, addition));
  print(
    '  ✓ app_features.dart (AppFeatures.${vars['__moduleCamel__']} = false)',
  );
}

void _appendBootstrapRegistration(Map<String, String> vars) {
  final file = File('lib/modules/modules_bootstrap.dart');
  var content = file.readAsStringSync();
  final module = vars['__module__']!;
  final featurePascal = vars['__Module__']!;
  final camel = vars['__moduleCamel__']!;

  const importMarker =
      "import 'package:app_template/modules/sync/sync_plugin.dart';";
  final newImport =
      "$importMarker\n"
      "import 'package:app_template/modules/$module/${module}_plugin.dart';";
  if (!content.contains(importMarker)) {
    die('لم أجد نقطة إدراج الـimport بـ${file.path}.');
  }
  content = content.replaceFirst(importMarker, newImport);

  // علامةٌ ثابتة لا آخرُ موديول: آخرُ موديولٍ يتبدّل، والعلامة تبقى.
  const registrationMarker =
      '    // scaffold_module: موديولٌ جديد فوق هذا السطر';
  final newRegistration =
      '    if (AppFeatures.$camel) {\n'
      '      await ${featurePascal}Plugin.initialize(di);\n'
      '    }\n'
      '$registrationMarker';
  if (!content.contains(registrationMarker)) {
    die('لم أجد نقطة تسجيل الموديول بـ${file.path}.');
  }
  content = content.replaceFirst(registrationMarker, newRegistration);

  file.writeAsStringSync(content);
  print(
    '  ✓ modules_bootstrap.dart (${featurePascal}Plugin.initialize موصولٌ بعلَمه)',
  );
}

void _appendModulesTableRow(Map<String, String> vars) {
  final file = File('readme/modules/30_MODULES.md');
  const marker = '<!-- scaffold_module: صفٌّ جديد فوق هذا السطر -->';
  final module = vars['__module__']!;
  final camel = vars['__moduleCamel__']!;
  final row =
      '| `$module/` — TODO صِفه | `$camel` | ⬜ OFF | TODO | — | '
      '[`SETUP.md`](../lib/modules/$module/SETUP.md) |';
  final content = file.existsSync() ? file.readAsStringSync() : '';
  if (!content.contains(marker)) {
    print('  ⚠️   لم أجد نقطة الإدراج بـ${file.path} — أضف الصفّ يدوياً:');
    print('      $row');
    return;
  }
  file.writeAsStringSync(content.replaceFirst(marker, '$row\n$marker'));
  print('  ✓ readme/modules/30_MODULES.md (الوصف وما يحتاجه لا يزالان TODO)');
}

// ── Health checks ─────────────────────────────────────────────────────────────

Future<bool> _runHealthChecks() async {
  header('🩺  فحوصات ما بعد التوليد');
  var allPassed = true;
  allPassed &= await _check('🔍  dart analyze lib', 'dart', ['analyze', 'lib']);
  allPassed &= await _check('🧪  flutter test', 'flutter', ['test']);
  allPassed &= await _check('🏗   check_structure', 'dart', [
    'run',
    'scripts/check_structure.dart',
  ]);
  return allPassed;
}

Future<bool> _check(String label, String exe, List<String> args) async {
  section(label);
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

/// كلُّ موديولٍ يحتاج إشارةً بجرد النقل أو سبباً لغيابها — `port_signals_test`
/// يُفشل الناقص. والمولَّد للتوّ لا قدرةَ فيه بعد تُكشف، فيُكتب له استثناءٌ
/// بـ`TODO` ظاهر: يمرّ الاختبار، ويبقى البند مقروءاً حتى يُستبدل.
void _appendPortSignalTodo(Map<String, String> vars) {
  final file = File('scripts/src/port_signals.dart');
  const anchor = 'const portSignalExemptions = <String, String>{';
  final module = vars['__module__']!;
  final content = file.existsSync() ? file.readAsStringSync() : '';
  if (!content.contains(anchor)) {
    print('  ⚠️   لم أجد portSignalExemptions — أضف إشارةً للموديول يدوياً.');
    return;
  }
  final entry =
      "  'module:$module':\n"
      "      'TODO — موديولٌ جديد: أضف PortSignal تكشف قدرته، أو سبباً لغيابها',";
  file.writeAsStringSync(content.replaceFirst(anchor, '$anchor\n$entry'));
  print('  ✓ scripts/src/port_signals.dart (استثناءٌ TODO — استبدله بإشارة)');
}
