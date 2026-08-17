// ignore_for_file: avoid_print
/// توليد الكود التلقائي للمشروع (4 خطوات):
///   1. build_runner  — Retrofit · Freezed · Injectable · AutoRoute
///   2. locale_keys.g.dart   — مفاتيح EasyLocalization
///   3. codegen_loader.g.dart — runtime loader (CodegenLoader)
///   4. permission_keys.g.dart — مفاتيح الصلاحيات من permissions.lock.json
///
/// تشغيل من جذر المشروع:
///   dart run scripts/codegen.dart
library;

import 'dart:io';

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  _header('⚙️   codegen — code generation');

  // 1. build_runner
  await _stream(
    '🔨  build_runner',
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
  );

  // 2. locale_keys.g.dart
  await _stream(
    '🌍  locale_keys.g.dart',
    'dart',
    [
      'run', 'easy_localization:generate',
      '-f', 'keys',
      '-O', 'lib/resources',
      '-S', 'assets/translations',
      '-o', 'locale_keys.g.dart',
    ],
  );

  // 3. codegen_loader.g.dart (runtime reader — إلزامي مع locale_keys)
  await _stream(
    '🌍  codegen_loader.g.dart',
    'dart',
    [
      'run', 'easy_localization:generate',
      '-f', 'json',
      '-O', 'lib/resources',
      '-S', 'assets/translations',
      '-o', 'codegen_loader.g.dart',
    ],
  );

  // 4. permission_keys.g.dart — من `permissions.lock.json` المُلتزَم به.
  //
  //    **لا شبكة، ولا خادم، ولا الباك على الجهاز.** وهذا بيت القصيد: مطوّر
  //    الفرونت يبني بلا أن يملك مصدر الباك إطلاقاً. وتحديث القفل عملية منفصلة
  //    تُشغَّل حين تتغيّر صلاحيات الباك فعلاً — راجع `sync_permission_keys.dart`.
  //
  //    يُتخطّى بلا ضجيج إن لم يكن المشروع يستعمل الصلاحيات أصلاً (لا ملف قفل).
  if (File('permissions.lock.json').existsSync()) {
    await _stream('🔑  permission_keys.g.dart', 'dart', [
      'run',
      'scripts/sync_permission_keys.dart',
    ]);
  }

  _footer('✅  codegen done');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// يشغّل أمراً مع إخراج حيّ في الوقت الفعلي (streaming).
Future<void> _stream(String label, String exe, List<String> args) async {
  _section(label);
  final process = await Process.start(exe, args, runInShell: true);

  // أخرج stdout و stderr مباشرة — المستخدم يرى التقدم فوراً
  await Future.wait([
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);

  final code = await process.exitCode;
  if (code != 0) _die('فشل الأمر (exit $code): $exe ${args.join(' ')}');
  print('');
}

void _header(String msg)  => print('\n${'─' * 60}\n  $msg\n${'─' * 60}');
void _footer(String msg)  => print('\n${'─' * 60}\n  $msg\n${'─' * 60}\n');
void _section(String msg) => print('\n▸ $msg');
void _die(String msg)     { print('\n❌  $msg\n'); exit(1); }
