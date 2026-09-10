import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/domain/sync_queue_signal.dart';

/// **الكاتب يُعلن، ولا يُسأل.**
///
/// وقبل هذا الجرس كان المحرّك يستيقظ بمؤقّتٍ دوريّ يسأل «هل من جديد؟» ويكاد لا
/// يجد شيئاً — سؤالٌ بلا سبب، وبتطبيقٍ ميدانيٍّ على بيانات الجوّال ذلك بطاريةٌ
/// وحزمةٌ تُنفقان على العدم.
void main() {
  test('a listener hears every notify', () async {
    final signal = SyncQueueSignal();
    final heard = <int>[];
    final sub = signal.stream.listen((_) => heard.add(heard.length));

    signal.notify();
    signal.notify();
    await Future<void>.delayed(Duration.zero);

    expect(heard, hasLength(2));
    await sub.cancel();
    await signal.dispose();
  });

  test('it is a broadcast — more than one listener may follow the queue', () async {
    final signal = SyncQueueSignal();
    var a = 0;
    var b = 0;
    final subA = signal.stream.listen((_) => a++);
    final subB = signal.stream.listen((_) => b++);

    signal.notify();
    await Future<void>.delayed(Duration.zero);

    expect([a, b], [1, 1]);
    await subA.cancel();
    await subB.cancel();
    await signal.dispose();
  });

  test('notifying with nobody listening is harmless', () async {
    final signal = SyncQueueSignal();

    // يقع فعلاً: كتابةٌ تسبق `SyncController.init`، أو تقع بعد `dispose`.
    expect(signal.notify, returnsNormally);
    await signal.dispose();
  });

  _wiring();
}

/// **والجرسُ بلا قارعٍ ولا سامعٍ لا يفعل شيئاً.**
///
/// وهذا ما لا يمسكه المصرِّف: `queueSignal` حقلٌ اختياريّ (`?`) — بوّابةٌ تُبنى
/// بلا ضبطه تُصرَّف نظيفةً وتصمت للأبد. والقياسُ مصدريّ لأن السلسلة تُركَّب
/// بـ`sync_bootstrap.dart` لا بمنشئٍ يُختبَر.
void _wiring() {
  group('the bell is rung and heard', () {
    test('the write gateway rings after a row enters the queue', () {
      final src = File(
        'lib/modules/sync/data/sql_sync_write_gateway.dart',
      ).readAsStringSync();

      expect(
        src,
        contains('queueSignal?.notify()'),
        reason: 'a queued row that rings nothing waits for a timer',
      );
    });

    test('bootstrap gives the gateway its bell, and the controller hears it', () {
      final src = File(
        'lib/modules/sync/integration/sync_bootstrap.dart',
      ).readAsStringSync();

      expect(
        src,
        contains('..queueSignal = getIt<SyncQueueSignal>()'),
        reason: 'the field is nullable — an unset bell compiles and stays mute',
      );
      // **الترتيبُ لا الوجود**: `getIt<SyncQueueSignal>()` يظهر بمواضع عدّة
      // بالملف، والمقصودُ أن يُمرَّر إلى `SyncController` بالذات.
      //
      // والحدُّ **نافذةُ أحرفٍ** لا `indexOf('),')`: كلُّ وسيطٍ ينتهي بـ`(),`
      // فيقع القصُّ عند الوسيط الأول — وهو خطأٌ يجعل الاختبار يفشل على كودٍ
      // صحيح.
      final at = src.indexOf('SyncController(');
      final call = src.substring(at, at + 400);
      expect(
        call,
        contains('getIt<SyncQueueSignal>()'),
        reason: 'nobody listening means the bell rings into an empty room',
      );
    });
  });
}
