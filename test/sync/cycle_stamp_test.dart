import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **«آخر مزامنة ناجحة» — والكلمةُ المهمّة «ناجحة».**
///
/// وكان السطرُ يُملأ `null` حرفياً: لا شيء بالموديول يسجّل انتهاء دورة، فتقول
/// البطاقة «لم تتم أي مزامنة بعد» **أبداً** — بعد كل مزامنةٍ ناجحة، وبعد مئة.
///
/// والقياسُ مصدريّ: الختمُ يكتب بـsqflite، والمقصودُ هنا **موضعُه من الدورة**
/// لا كتابتُه — وهو ما يفرّق بين ختمٍ صادق وختمٍ يكذب.
void main() {
  late String engine;

  setUp(() {
    engine = File('lib/modules/sync/engine/sync_engine.dart').readAsStringSync();
  });

  test('the stamp is written inside try, never in finally', () {
    // دورةٌ خرجت من `catch` **انتهت ولم تنجح**. وختمٌ بـ`finally` يجعل كلَّ
    // إخفاقٍ يُقرأ نجاحاً — وما تعرضه الشاشة هو ما يبني عليه المستخدم قرارَه.
    final at = engine.indexOf('_cycleStamp.markSuccess()');
    expect(at, greaterThan(-1), reason: 'nothing stamps the cycle');

    final catchAt = engine.indexOf('} catch (e, st) {', at);
    final finallyAt = engine.indexOf('} finally {', at);
    expect(
      catchAt,
      lessThan(finallyAt),
      reason: 'the stamp must sit above the catch, not in the finally',
    );
  });

  test('a failed phase blocks the stamp', () {
    expect(
      engine,
      contains('if (!_cycleFailed) await _cycleStamp.markSuccess()'),
      reason: 'a cycle that pushed nine rows and failed the tenth is not '
          'a successful sync',
    );
  });

  test('the flag is reset when a cycle starts', () {
    // بلا التصفير يبقى إخفاقُ دورةٍ سابقة يمنع ختمَ كل ما بعدها.
    expect(engine, contains('_cycleFailed = false;'));
  });

  test('the flag is raised by the catch', () {
    // **الـcatch الذي يخصّ الدورة**, لا أوّلَ `catch` بالملف — وبينهما
    // معالجاتٌ أخرى بحدودها الخاصّة.
    final stampAt = engine.indexOf('_cycleStamp.markSuccess()');
    final catchAt = engine.indexOf('} catch (e, st) {', stampAt);
    expect(
      engine.substring(catchAt, catchAt + 200),
      contains('_cycleFailed = true'),
    );
  });

  test('wiping an account forgets the stamp', () {
    // وقتُ مزامنةٍ لحسابٍ آخر أسوأ من لا وقت.
    final wiper = File(
      'lib/modules/sync/integration/sync_local_data_wiper.dart',
    ).readAsStringSync();

    expect(wiper, contains("'sync_meta'"));
  });
}
