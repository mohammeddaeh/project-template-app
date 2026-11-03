// ignore_for_file: avoid_print
/// ما تتشاركه سكربتات `scripts/`: طباعةُ الأقسام، والخروجُ برسالة، وحمايةُ
/// `main` من stack trace خامّ على خطأٍ متوقَّع.
library;

import 'dart:async';
import 'dart:io';

final _rule = '─' * 60;

void header(String msg) => print('\n$_rule\n  $msg\n$_rule');

void footer(String msg) => print('\n$_rule\n  $msg\n$_rule\n');

void section(String msg) => print('\n▸ $msg');

/// يطبع الرسالة ويُنهي العملية.
Never die(String msg, {int code = 1}) {
  print('\n❌  $msg\n');
  exit(code);
}

/// يشغّل [body]، و**خطأٌ متوقَّع** (ملفٌّ غائب · JSON تالف · أمرٌ لم يُوجد ·
/// خادمٌ لا يُجيب · حالةٌ غير صالحة) يصير سطراً واحداً و`exit(2)` لا stack trace.
///
/// الخطأُ الذي لا يقع بهذه الأصناف يبقى كما هو: هو عطلٌ بالسكربت نفسه، وأثرُه
/// كاملاً هو ما يُصلحه.
Future<void> runCli(FutureOr<void> Function() body) async {
  try {
    await body();
  } on FileSystemException catch (e) {
    die('${e.message}: ${e.path ?? ''}', code: 2);
  } on FormatException catch (e) {
    die('صيغةٌ غير صالحة — ${e.message}', code: 2);
  } on ProcessException catch (e) {
    die('تعذّر تشغيل `${e.executable}` — ${e.message}', code: 2);
  } on SocketException catch (e) {
    die('تعذّر الاتصال — ${e.message}', code: 2);
  } on StateError catch (e) {
    die(e.message, code: 2);
  }
}

String toSnakeCase(String input) => input
    .trim()
    .replaceAll(RegExp(r'[\s-]+'), '_')
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m.group(1)}_${m.group(2)}',
    )
    .toLowerCase();

String toPascalCase(String snake) => snake
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join();

String toCamelCase(String snake) {
  final pascal = toPascalCase(snake);
  return pascal.isEmpty
      ? pascal
      : pascal[0].toLowerCase() + pascal.substring(1);
}
