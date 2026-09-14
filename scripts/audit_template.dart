// ignore_for_file: avoid_print
/// تدقيقٌ ذاتيّ للقالب — يُشغِّل آلياً ما جرى يدوياً بمحادثة تدقيق كاملة
/// (2026-09-13/14): وصل كل موديول اختياري بإقلاعه · الفجوة الحرجة إن فُعِّل
/// علَم المزامنة بلا عقود منفَّذة · مسارات مسجَّلة بلا نقطة تنقّل إليها ·
/// ملفات `readme/` خارج جدول التزامن الإلزامي بـ`CLAUDE.md`.
///
/// **تشخيصيٌّ استشاريّ، لا فاحص CI حاجب** (خلافاً لـ`check_structure.dart`):
/// كل نتيجة هنا **مرشَّحة للمراجعة البشرية**، لا حكماً قاطعاً — مسارٌ بلا
/// مستهلكٍ ظاهر قد يكون منتظراً بقصد (راجع `10_ARCHITECTURE.md` §«جرد المبنيّ
/// بلا مستهلك»). **الاستثناء الوحيد** الذي يُخفق الأمر (`exit(1)`) هو فجوة
/// المزامنة الحرجة — صفرُ زيفٍ إيجابيٍّ ممكنٍ فيها: إمّا العلَم مفعَّلٌ وصفرُ
/// عقودٍ مسجَّلة، أو لا.
///
/// راجع `readme/41_ROADMAP.md` بند #04 للسياق الكامل.
///
/// تشغيل من جذر المشروع:
///   dart run scripts/audit_template.dart
library;

import 'dart:io';

Future<void> main(List<String> args) async {
  _header('🩺  audit_template — تدقيق ذاتي للقالب');

  var criticalFound = false;

  _section('١) وصل الموديولات الاختيارية بإقلاعها');
  _checkModuleWiring();

  _section('٢) الفجوة الحرجة — علَمٌ مفعَّل بلا عقودٍ منفَّذة');
  criticalFound |= _checkSyncContracts();

  _section('٣) مسارات مسجَّلة بلا نقطة تنقّل ظاهرة');
  _checkRouteReachability();

  _section('٤) ملفات readme/ خارج جدول التزامن بـCLAUDE.md');
  _checkDocSyncTable();

  _footer(
    criticalFound
        ? '❌  عُثر على فجوة حرجة — راجع القسم ٢ أعلاه'
        : '✅  لا فجوة حرجة. النتائج الأخرى مرشَّحاتٌ للمراجعة البشرية — راجع readme/10_ARCHITECTURE.md',
  );

  if (criticalFound) exit(1);
}

// ── 1. Module wiring ─────────────────────────────────────────────────────────

void _checkModuleWiring() {
  final bootstrapFile = File('lib/modules/modules_bootstrap.dart');
  if (!bootstrapFile.existsSync()) {
    print('  ⚠️   lib/modules/modules_bootstrap.dart غير موجود — تُخطَّى.');
    return;
  }
  final bootstrapContent = bootstrapFile.readAsStringSync();

  final modulesDir = Directory('lib/modules');
  if (!modulesDir.existsSync()) return;

  final moduleDirs = modulesDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  var okCount = 0;
  for (final name in moduleDirs) {
    final entryFile = Directory('lib/modules/$name')
        .listSync()
        .whereType<File>()
        .map((f) => f.path.split(Platform.pathSeparator).last)
        .where((f) => f == '${name}_plugin.dart' || f == '${name}_module.dart')
        .toList();

    if (entryFile.isEmpty) {
      print('  ◌  $name: لا ملفّ مدخلٍ باسم ${name}_plugin.dart أو ${name}_module.dart — تُخطَّى (قد يكون sub-package لموديول آخر)');
      continue;
    }

    final imported = bootstrapContent.contains('modules/$name/${entryFile.first}');
    if (imported) {
      okCount++;
    } else {
      print('  ⚠️   $name: ${entryFile.first} موجود لكن غير مستورَد بـmodules_bootstrap.dart — راجع يدوياً');
    }
  }
  print('  ✓ $okCount من ${moduleDirs.length} موديولاً موصولٌ بإقلاعه');
}

// ── 2. Sync contract gap (the only exit-code-affecting check) ────────────────

bool _checkSyncContracts() {
  final featuresFile = File('lib/core/platform/features/app_features.dart');
  if (!featuresFile.existsSync()) {
    print('  ⚠️   app_features.dart غير موجود — تُخطَّى.');
    return false;
  }
  final offlineSyncEnabled = RegExp(
    r'static const offlineSync = true;',
  ).hasMatch(featuresFile.readAsStringSync());

  var implementationCount = 0;
  for (final file in _dartFilesUnder('lib')) {
    // الملف المُعرِّف نفسه ليس تنفيذاً.
    if (file.path.endsWith('sync_feature_contract.dart')) continue;
    final content = file.readAsStringSync();
    if (RegExp(
      r'(extends|implements)\s+SyncFeatureContractBase|@LazySingleton\(as:\s*SyncFeatureContractBase\)',
    ).hasMatch(content)) {
      implementationCount++;
      print('  • تنفيذ عُثر عليه: ${file.path}');
    }
  }

  print('  عدد عقود SyncFeatureContractBase المنفَّذة: $implementationCount');
  print('  AppFeatures.offlineSync: ${offlineSyncEnabled ? 'true' : 'false'}');

  if (offlineSyncEnabled && implementationCount == 0) {
    print(
      '  ❌  حرج: العلَم مفعَّلٌ وصفرُ عقودٍ منفَّذة — التطبيق يعمل بالكامل على\n'
      '      الشبكة بصمت. راجع lib/modules/sync/PLAN.md ب١٣/ب١٤ قبل الشحن.',
    );
    return true;
  }
  print('  ✓ لا فجوة — ${offlineSyncEnabled ? 'العقود موجودة' : 'العلَم مطفأ'}');
  return false;
}

// ── 3. Route reachability ────────────────────────────────────────────────────

void _checkRouteReachability() {
  final routerDart = File('lib/routes/router.dart');
  if (!routerDart.existsSync()) {
    print('  ⚠️   lib/routes/router.dart غير موجود — تُخطَّى.');
    return;
  }

  final routePageClasses = <String>[];
  for (final file in _dartFilesUnder('lib')) {
    if (file.path.endsWith('router.gr.dart')) continue;
    final content = file.readAsStringSync();
    for (final match in RegExp(
      r"@RoutePage\((?:name:\s*'(\w+)')?\)\s*\nclass\s+(\w+)",
    ).allMatches(content)) {
      final explicitName = match.group(1);
      final className = match.group(2)!;
      routePageClasses.add(explicitName ?? _deriveRouteName(className));
    }
  }

  // نصّ البحث: كل شيء عدا التعريف نفسه (router.dart's AutoRoute list) — نبحث
  // هل اسم الـRoute يظهر باستدعاء تنقّل (push/replace) بمكانٍ آخر بـlib/.
  final searchableContent = StringBuffer();
  for (final file in _dartFilesUnder('lib')) {
    if (file.path.endsWith('router.gr.dart')) continue;
    searchableContent.writeln(file.readAsStringSync());
  }
  final haystack = searchableContent.toString();

  var orphanCount = 0;
  for (final routeName in routePageClasses.toSet()) {
    // occurrences: مرّة بجدول AutoRoute بـrouter.dart + أي استخدام فعلي.
    final occurrences = RegExp(
      '\\b$routeName\\b',
    ).allMatches(haystack).length;
    // occurrence واحدة فقط = التصريح بجدول AutoRoute ولا استدعاء تنقّل آخر.
    if (occurrences <= 1) {
      orphanCount++;
      print('  ◌  $routeName — لا استدعاء تنقّل ظاهر بـlib/ (قد يكون مقصوداً — راجع 10_ARCHITECTURE.md)');
    }
  }
  print('  $orphanCount من ${routePageClasses.length} مساراً بلا استدعاء تنقّل ظاهر');
}

// ── 4. Doc-sync table completeness ───────────────────────────────────────────

void _checkDocSyncTable() {
  final claudeFile = File('CLAUDE.md');
  if (!claudeFile.existsSync()) {
    print('  ⚠️   CLAUDE.md غير موجود بجذر المشروع — تُخطَّى.');
    return;
  }
  final claudeContent = claudeFile.readAsStringSync();

  final readmeDir = Directory('readme');
  if (!readmeDir.existsSync()) return;

  final readmeFiles = readmeDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .map((f) => f.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  var missing = 0;
  for (final name in readmeFiles) {
    if (!claudeContent.contains(name)) {
      missing++;
      print('  ⚠️   readme/$name غير مذكور بجدول «Mandatory Documentation Sync» بـCLAUDE.md');
    }
  }
  print('  $missing من ${readmeFiles.length} ملفاً بجذر readme/ غير مذكور بالجدول');
  print('  (ملفات 90_archive/ مُستثناة عمداً — تغطّيها القاعدة العامة "لا يُصان")');
}

/// نمط auto_route الافتراضي عند غياب `@RoutePage(name: ...)` صريح: يُسقط
/// لاحقة `Screen` أو `Page` ويُلحق `Route` — وإلا يُلحق `Route` بالاسم كاملاً.
String _deriveRouteName(String className) {
  for (final suffix in ['Screen', 'Page']) {
    if (className.endsWith(suffix)) {
      return '${className.substring(0, className.length - suffix.length)}Route';
    }
  }
  return '${className}Route';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Iterable<File> _dartFilesUnder(String dirPath) sync* {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

void _header(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}');
void _footer(String msg) => print('\n${'─' * 60}\n  $msg\n${'─' * 60}\n');
void _section(String msg) => print('\n▸ $msg');
