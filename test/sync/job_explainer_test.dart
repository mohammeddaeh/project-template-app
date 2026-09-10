import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/sync/domain/sync_job_explainer.dart';

/// **ماذا سيصل الخادمَ من هذا الصفّ — وما الذي يحجز الباقي.**
///
/// والعقدُ هنا كلُّه قيَمٌ وأسماءُ مفاتيح: لا نصَّ واجهةٍ ولا ترجمة. وهو ما
/// يجعل الشريحةَ تجيب والشاشةَ تعرض، بلا أن تنسخ إحداهما قواعدَ الأخرى.
class _Explainer implements SyncJobExplainer {
  _Explainer(this._parts);
  final List<SyncJobPart> _parts;

  @override
  String get entityName => 'notes';

  @override
  List<SyncJobPart> explain(Map<String, dynamic> row) {
    // صفٌّ لا يُفهم يُردّ بقائمةٍ فارغة، لا برمية.
    if (row['id'] == null) return const [];
    return _parts;
  }

  @override
  Future<bool?> revert({
    required String localId,
    required String partKey,
    required String fieldKey,
  }) async => null;

  @override
  SyncFullRevertKind planFullRevert(Map<String, dynamic> row) =>
      row['id'] == null
      ? SyncFullRevertKind.unavailable
      : SyncFullRevertKind.restore;

  @override
  Future<SyncFullRevertKind?> revertAll({required String localId}) async =>
      null;
}

void main() {
  test('a row it cannot read yields an empty list, never a throw', () {
    final explainer = _Explainer(const []);

    // الورقةُ تعرض ما تعرف وتصمت عمّا لا تعرف، ولا تُسقط الشاشة كلَّها لصفٍّ
    // واحدٍ تالف.
    expect(() => explainer.explain(const {}), returnsNormally);
    expect(explainer.explain(const {}), isEmpty);
  });

  test('a part that is held names what it is missing', () {
    const part = SyncJobPart(
      key: 'basic',
      state: SyncJobPartState.held,
      missingKeys: ['title', 'photos'],
    );

    // «القسم الأول محجوز» وحدها تُقرأ عطلاً؛ و«محجوز — ينقصه العنوان والصور»
    // تُقرأ عملاً باقياً.
    expect(part.missingKeys, isNotEmpty);
  });

  test('operations say what a person did, not that a value changed', () {
    // «تغيّر» لا يُتراجَع عنه بثقة؛ ومن ألغى اختياراً يعرف أنه ألغاه.
    expect(SyncJobOpKind.values, [
      SyncJobOpKind.added,
      SyncJobOpKind.edited,
      SyncJobOpKind.cleared,
    ]);
  });

  test('an unreadable row plans no full revert — a guess is not offered', () {
    final explainer = _Explainer(const []);

    // فعلٌ لا رجعةَ فيه لا يُخمَّن: الحوارُ كان يَعِد بـ«عودةٍ إلى ما عند
    // الخادم» ثم يمحو صفّاً لا يعرفه الخادمُ أصلاً.
    expect(
      explainer.planFullRevert(const {}),
      SyncFullRevertKind.unavailable,
    );
  });

  test('the three revert kinds are distinct, and none is a default', () {
    // ⛔ **و`discard` لا رجعةَ فيه** — محوُ صفٍّ وملفّاته. فخلطُه بـ`restore`
    //    (عودةٌ إلى لقطةِ خادم، ولا يضيع فيها شيء) يجعل زرّاً واحداً يفعل
    //    فعلين مختلفين تماماً بحسب حالةٍ لا يراها الضاغط.
    //
    // و`unavailable` ليست «لا شيء»: صفٌّ يعرفه الخادمُ ولا لقطةَ له — محوُه
    // يُخفي عن صاحبه شيئاً قائماً هناك، وردُّه إلى لقطةٍ لا وجود لها مستحيل.
    expect(SyncFullRevertKind.values, hasLength(3));
    expect(
      SyncFullRevertKind.values.toSet(),
      {
        SyncFullRevertKind.restore,
        SyncFullRevertKind.discard,
        SyncFullRevertKind.unavailable,
      },
    );
  });

  test('parts compare by value — the screen may rebuild without flicker', () {
    const a = SyncJobPart(key: 'basic', state: SyncJobPartState.sending);
    const b = SyncJobPart(key: 'basic', state: SyncJobPartState.sending);

    expect(a, b);
  });

  test('the module exports it — a contract the feature cannot see is dead', () {
    final surface = File(
      'lib/modules/sync/sync_plugin.dart',
    ).readAsStringSync();

    expect(surface, contains('sync_job_explainer.dart'));
  });
}
