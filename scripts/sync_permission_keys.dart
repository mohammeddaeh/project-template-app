// ignore_for_file: avoid_print
/// يربط مفاتيح الصلاحيات بين الباك والفرونت — عبر **ملف قفل مُلتزَم به**.
///
/// ```bash
/// # الاستعمال اليومي — بلا شبكة، بلا خادم، بلا الباك على جهازك:
/// dart run scripts/sync_permission_keys.dart
///
/// # تحديث القفل حين تتغيّر صلاحيات الباك:
/// cd ../backend_template && npm run --silent print:permissions > ../perms.json
/// cd ../app_template && dart run scripts/sync_permission_keys.dart --update --from ../perms.json
/// #   أو من خادم يعمل:
/// dart run scripts/sync_permission_keys.dart --update --url http://localhost:3000/api/v1 --token <t>
///
/// # التحقّق (للـCI): يفشل إن كان القفل متقادماً
/// dart run scripts/sync_permission_keys.dart --verify --from ../perms.json
/// ```
///
/// ── المشكلة ────────────────────────────────────────────────────────────────
///
/// مشروعان منفصلان يجب أن يتّفقا على مجموعة نصوص. والخطأ فيها **صامت**:
/// `Can(permission: 'note.update')` بدل `notes.update` يُخفي العنصر عن الجميع
/// للأبد، بلا انهيار ولا سجلّ ولا اختبار فاشل — ولا يُميَّز عن صلاحية لم تُمنح.
///
/// ── لماذا ملف قفل، وليس نداءً للخادم عند كل بناء ──────────────────────────
///
/// [_lockPath] **مُلتزَم به في git**، وهذا ما يحلّ حالة «الباك عند شخص والفرونت
/// عند آخر»:
///
/// | | بلا قفل | بقفل |
/// |---|---|---|
/// | مطوّر الفرونت يحتاج مصدر الباك | نعم | **لا** |
/// | البناء بلا إنترنت | يفشل | **يعمل** |
/// | تغيّر الصلاحيات يُرى في المراجعة | لا | **diff صريح** |
/// | بناءان متطابقان يُنتجان نفس الشيء | ليس بالضرورة | **دائماً** |
///
/// نفس منطق `pubspec.lock` و`package-lock.json` بالضبط: الاعتماد يُلتقَط مرّة،
/// ويُراجَع كنصّ، ويعاد إنتاجه حرفياً.
///
/// **والقفل قد يشيخ** — ولهذا `--verify`: يقارنه بالخادم ويفشل عند الاختلاف،
/// فيُكتشف التقادم في الـCI لا عند مستخدم يشتكي من زرّ مفقود.
library;

import 'dart:convert';
import 'dart:io';

const _lockPath = 'permissions.lock.json';
const _outputPath = 'lib/resources/permission_keys.g.dart';

Future<void> main(List<String> args) async {
  final update = args.contains('--update');
  final verify = args.contains('--verify');

  if (update && verify) {
    stderr.writeln('❌ اختر أحدهما: --update أو --verify.');
    exitCode = 1;
    return;
  }

  if (!update && !verify) {
    // الحالة الشائعة: ولّد من القفل. لا شبكة، لا خادم، لا مفاجآت.
    final keys = _readLock();
    if (keys == null) return;
    _writeGenerated(keys);
    return;
  }

  final incoming = await _readSource(args);
  if (incoming == null || incoming.isEmpty) {
    stderr.writeln(
      '❌ لم يصل أي مفتاح.\n'
      '   --from: تأكّد أن الملف ناتج عن `npm run --silent print:permissions`.\n'
      '   --url : تأكّد أن الخادم يعمل وأن التوكن صالح.',
    );
    exitCode = 1;
    return;
  }

  if (verify) {
    _verify(incoming);
    return;
  }

  _writeLock(incoming);
  _writeGenerated(incoming);
}

// ── القفل ───────────────────────────────────────────────────────────────────

List<String>? _readLock() {
  final file = File(_lockPath);
  if (!file.existsSync()) {
    stderr.writeln(
      '❌ لا يوجد $_lockPath.\n'
      '   أنشئه مرّة واحدة:\n'
      '     cd ../backend_template && npm run --silent print:permissions > ../perms.json\n'
      '     cd ../app_template && dart run scripts/sync_permission_keys.dart --update --from ../perms.json',
    );
    exitCode = 1;
    return null;
  }

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['keys'] as List<dynamic>? ?? const []).whereType<String>().toList();
}

void _writeLock(List<String> keys) {
  final lock = {
    '_comment': 'GENERATED — do not edit by hand. '
        'Run: dart run scripts/sync_permission_keys.dart --update --from <perms.json>',
    'source': 'backend_template — every key its routes enforce, plus the grant-only umbrellas',
    'keys': keys,
  };
  File(_lockPath).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(lock)}\n');
  print('🔒 ${keys.length} مفتاحاً → $_lockPath');
}

/// يقارن القفل بالمصدر ويفشل عند الاختلاف — يسمّي الفرق في الاتجاهين.
///
/// الاتجاهان مختلفان في المعنى: مفتاح **جديد بالباك** يعني بوابةً لم تُبنَ بعد،
/// ومفتاح **حُذف من الباك** يعني بوابةً في الفرونت لا تحرس شيئاً — وكلاهما
/// يستحقّ أن يُسمّى بدل «الملفان مختلفان».
void _verify(List<String> incoming) {
  final locked = _readLock();
  if (locked == null) return;

  final added = incoming.where((k) => !locked.contains(k)).toList();
  final removed = locked.where((k) => !incoming.contains(k)).toList();

  if (added.isEmpty && removed.isEmpty) {
    print('✅ $_lockPath مطابق للباك (${locked.length} مفتاحاً)');
    return;
  }

  stderr.writeln('❌ $_lockPath متقادم:\n');
  for (final k in added) {
    stderr.writeln('   + $k   (يفرضه الباك ولا وجود له بالقفل)');
  }
  for (final k in removed) {
    stderr.writeln('   - $k   (بالقفل ولم يعد الباك يفرضه)');
  }
  stderr.writeln(
    '\n   شغّل: dart run scripts/sync_permission_keys.dart --update --from <perms.json>',
  );
  exitCode = 1;
}

// ── المصادر ─────────────────────────────────────────────────────────────────

Future<List<String>?> _readSource(List<String> args) async {
  final from = _arg(args, '--from');
  if (from != null) return _readDump(from);

  return _fetchFromServer(
    _arg(args, '--url') ?? 'http://localhost:3000/api/v1',
    _arg(args, '--token'),
  );
}

/// ناتج `npm run --silent print:permissions` — المفروض والمظلّات معاً.
///
/// المظلّات مشمولة لأن الواجهة قد تبني عليها بحقّ («أظهر هذا القسم لمن يملك
/// المورد كله»)، فاستبعادها كان سيجعل مفتاحاً صالحاً يبدو خطأً مطبعياً.
List<String>? _readDump(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('❌ لا ملف على المسار: $path');
    return null;
  }

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final enforced = (json['enforced'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((e) => e['key'] as String? ?? '')
      .where((k) => k.isNotEmpty);
  final umbrellas =
      (json['umbrellas'] as List<dynamic>? ?? const []).whereType<String>();

  return <String>{...enforced, ...umbrellas}.toList()..sort();
}

/// يطلب `?include_declared=true` — **ما تفرضه المسارات**، لا ما يملكه الحساب.
/// التوليد من صلاحيات المستخدم الحالي يُنتج ثوابت تختفي حين يشغّله زميل بحساب
/// أقلّ صلاحية.
Future<List<String>?> _fetchFromServer(String baseUrl, String? token) async {
  final client = HttpClient();
  try {
    final request =
        await client.getUrl(Uri.parse('$baseUrl/authz/me?include_declared=true'));
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      stderr.writeln('❌ HTTP ${response.statusCode}: $body');
      return null;
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return (data['declared_keys'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList()
      ..sort();
  } finally {
    client.close();
  }
}

// ── التوليد ─────────────────────────────────────────────────────────────────

void _writeGenerated(List<String> keys) {
  File(_outputPath).writeAsStringSync(_render(keys));
  print('✅ ${keys.length} مفتاحاً → $_outputPath');
}

String _render(List<String> keys) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED — do not edit by hand.')
    ..writeln('// dart run scripts/sync_permission_keys.dart')
    ..writeln('//')
    ..writeln('// المصدر: permissions.lock.json (مُلتزَم به بـgit).')
    ..writeln('// استعمله بدل النصّ الخام:')
    ..writeln('//   Can(permission: PermKeys.notesUpdate, child: ...)')
    ..writeln('//')
    ..writeln('// مفتاحٌ حُذف من الباك يختفي من هنا فيكسر البناء عند كل استعمال')
    ..writeln('// له — وهذه هي الفائدة، لا إزعاجاً.')
    ..writeln()
    ..writeln('abstract final class PermKeys {')
    ..writeln('  const PermKeys._();');

  for (final key in keys) {
    buffer
      ..writeln()
      ..writeln('  /// `$key`')
      ..writeln("  static const String ${_identifier(key)} = '$key';");
  }

  buffer
    ..writeln()
    ..writeln('  /// كل المفاتيح — لشاشة تشخيص أو فحص.')
    ..writeln('  static const List<String> all = <String>[')
    ..writeAll(keys.map((k) => "    '$k',\n"))
    ..writeln('  ];')
    ..writeln('}');

  return buffer.toString();
}

/// `orders.delivery.update` → `ordersDeliveryUpdate` · `audit_log.view` →
/// `auditLogView`. النقطة والشرطة السفلية فاصلا كلمات.
String _identifier(String key) {
  final words = key.split(RegExp(r'[._]')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return 'unknown';

  return words.first +
      words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
