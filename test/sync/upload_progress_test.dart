import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/engine/attachment_upload_progress.dart';

/// **«كم صعد من هذا الملفّ» — نبضٌ يُبَثّ ولا يُخزَّن.**
///
/// ورفعُ ملفٍّ بمئة ميغابايت بلا نبضٍ يُقرأ **توقُّفاً**، فيقتل المستخدم التطبيقَ
/// ويعيد من الصفر.
void main() {
  late AttachmentUploadProgress progress;

  setUp(() => progress = AttachmentUploadProgress());
  tearDown(() => progress.dispose());

  test('a file that has not started has no fraction', () {
    expect(progress.fractionOf('a'), isNull);
  });

  test('a reported fraction is readable and broadcast', () async {
    var beats = 0;
    final sub = progress.stream.listen((_) => beats++);

    progress.report(attachmentId: 'a', sent: 50, total: 200);
    await Future<void>.delayed(Duration.zero);

    expect(progress.fractionOf('a'), 0.25);
    expect(beats, 1);
    await sub.cancel();
  });

  test('an unknown total is ignored, never divided by', () {
    // الخادمُ قد لا يعلن الطول، فيصل `-1`.
    progress.report(attachmentId: 'a', sent: 50, total: -1);
    progress.report(attachmentId: 'a', sent: 50, total: 0);

    expect(progress.fractionOf('a'), isNull);
  });

  test('the same fraction twice does not wake the screen again', () async {
    var beats = 0;
    final sub = progress.stream.listen((_) => beats++);

    progress.report(attachmentId: 'a', sent: 50, total: 200);
    progress.report(attachmentId: 'a', sent: 50, total: 200);
    await Future<void>.delayed(Duration.zero);

    // Dio ينبض مرّاتٍ كثيرة بنفس الكسر على وصلةٍ سريعة.
    expect(beats, 1);
    await sub.cancel();
  });

  test('it never exceeds 1.0', () {
    progress.report(attachmentId: 'a', sent: 300, total: 200);
    expect(progress.fractionOf('a'), 1.0);
  });

  test('clearing forgets the file and wakes the screen', () async {
    progress.report(attachmentId: 'a', sent: 50, total: 200);
    var beats = 0;
    final sub = progress.stream.listen((_) => beats++);

    progress.clear('a');
    await Future<void>.delayed(Duration.zero);

    expect(progress.fractionOf('a'), isNull);
    expect(beats, 1);
    await sub.cancel();
  });

  test('clearing a file that was never reported is silent', () async {
    var beats = 0;
    final sub = progress.stream.listen((_) => beats++);

    progress.clear('never-seen');
    await Future<void>.delayed(Duration.zero);

    expect(beats, 0);
    await sub.cancel();
  });

  test('files are tracked independently', () {
    progress.report(attachmentId: 'a', sent: 50, total: 200);
    progress.report(attachmentId: 'b', sent: 150, total: 200);

    expect(progress.fractionOf('a'), 0.25);
    expect(progress.fractionOf('b'), 0.75);
  });

  test('the manager detaches the hook AND clears — on both paths', () {
    // الهدفُ مفردٌ مشترك (`lazySingleton`)، وخطّافٌ متروكٌ موصولاً يجعل نبضاتِ
    // الملفّ التالي **تُنسب إلى السابق**. وكسرةٌ متروكة عند ٠٫٧ لملفٍّ أُكِّد
    // تجعل الشاشة تخلط «انتهى» بـ«توقّف عند سبعين بالمئة».
    final src = File(
      'lib/modules/sync/engine/attachment_upload_manager.dart',
    ).readAsStringSync();

    final at = src.indexOf('} finally {');
    expect(at, greaterThan(-1), reason: 'no finally — a throw leaks the hook');

    final block = src.substring(at, at + 400);
    expect(block, contains('target.onSendProgress = null'));
    expect(block, contains('_progress.clear('));
  });
}
