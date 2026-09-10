import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/di/get_it_all_extension.dart';
import 'package:app_template/modules/sync/domain/sync_refresh_task.dart';

/// **مهامُّ التحديث — وما يجعلها آمنةً بذيل الدورة.**
///
/// وعطلاها كلاهما صامت: مشروعٌ بلا مهمّةٍ واحدة تُسقط الدورةَ كلَّها برمية من
/// `getAll`، ومهمّةٌ تُخفق تُسقط دورةً اكتملت — فيُقرأ إخفاقُ لقطةٍ اختيارية
/// إخفاقَ مزامنةٍ كاملة.
class _Ok implements SyncRefreshTask {
  _Ok(this.name);
  @override
  final String name;
  var ran = 0;
  @override
  Future<void> refresh() async => ran++;
}

class _Throws implements SyncRefreshTask {
  @override
  String get name => 'broken';
  @override
  Future<void> refresh() async => throw StateError('server said no');
}

/// نفسُ الحلقة التي بـ`SyncEngine._processRefreshTasks` — تُعاد هنا لأن المحرّك
/// يحتاج عشرةَ تسجيلاتٍ ليُبنى، والمقيسُ **حدُّ الإخفاق** لا المحرّك.
Future<List<String>> runTasks(GetIt di) async {
  final failed = <String>[];
  for (final task in di.allOf<SyncRefreshTask>()) {
    try {
      await task.refresh();
    } catch (_) {
      failed.add(task.name);
    }
  }
  return failed;
}

void main() {
  late GetIt di;

  setUp(() => di = GetIt.asNewInstance());
  tearDown(() => di.reset());

  test('a project with no refresh task does NOT throw', () async {
    // `getAll` **ترمي** لنوعٍ غير مسجَّل — فالدورةُ كلُّها كانت تسقط.
    expect(await runTasks(di), isEmpty);
  });

  test('every registered task runs', () async {
    final a = _Ok('a');
    final b = _Ok('b');
    di.registerSingleton<SyncRefreshTask>(a, instanceName: 'a');
    di.registerSingleton<SyncRefreshTask>(b, instanceName: 'b');

    await runTasks(di);

    expect([a.ran, b.ran], [1, 1]);
  });

  test('one task that throws does not stop the others', () async {
    final after = _Ok('after');
    di.registerSingleton<SyncRefreshTask>(_Throws(), instanceName: 'broken');
    di.registerSingleton<SyncRefreshTask>(after, instanceName: 'after');

    final failed = await runTasks(di);

    expect(failed, ['broken']);
    expect(after.ran, 1, reason: 'an optional snapshot cannot block the rest');
  });

  test('the engine calls them, and with allOf rather than getAll', () {
    // حارسُ سلسلة: العقدُ بلا نداءٍ سطحٌ ميت، و`getAll` ترمي على الفراغ.
    final src = File(
      'lib/modules/sync/engine/sync_engine.dart',
    ).readAsStringSync();

    expect(src, contains('_processRefreshTasks()'));
    expect(src, contains('allOf<SyncRefreshTask>()'));
    expect(
      src.contains('getAll<SyncRefreshTask>()'),
      isFalse,
      reason: 'getAll throws when nothing is registered',
    );
  });
}
