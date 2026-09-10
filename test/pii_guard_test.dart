import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/modules/analytics/pii_guard.dart';

/// **لا يخرج من هذا الجهاز إلى التحليلات بريدٌ ولا كلمةُ مرورٍ ولا توكن.**
///
/// والعطلُ صامتٌ تماماً: حدثٌ يُرسَل، والطلبُ ينجح، والبيانُ عند مزوّدٍ ثالث
/// **ولا سبيل إلى سحبه**. ولا يمسكه تحليلٌ ولا اختبارُ واجهة — المفتاحُ نصٌّ
/// صالح، والقيمةُ نصٌّ صالح.
void main() {
  test('a clean event passes', () {
    expect(
      () => assertNoPii('track:open_unit', {'unit_id': 12, 'tab': 'tasks'}),
      returnsNormally,
    );
  });

  test('a banned key throws, and names itself', () {
    expect(
      () => assertNoPii('track:login', {'email': 'a@b.c'}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('email'), contains('track:login')),
        ),
      ),
    );
  });

  test('a banned word inside a longer key is caught too', () {
    // `user_email_hash` ليس `email` حرفاً — والمطابقةُ بالاحتواء لهذا بعينه.
    expect(
      () => assertNoPii('x', {'user_email_hash': 'abc'}),
      throwsStateError,
    );
  });

  test('a secret nested deeper than the top level is caught', () {
    expect(
      () => assertNoPii('x', {
        'ctx': {
          'auth': {'access_token': 'ey...'},
        },
      }),
      throwsStateError,
    );
  });

  test('a banned word in a VALUE is caught, not only in a key', () {
    // حدثٌ اسمُه `submit_password_form` يسرّب المعنى لا القيمة — والاسمُ نفسُه
    // يُرسَل إلى المزوّد.
    expect(() => assertNoPii('x', 'user password here'), throwsStateError);
  });

  test('the ban list covers every identifier this template can carry', () {
    for (final key in const [
      'email',
      'password',
      'token',
      'phone',
      'national_id',
      'nationalid',
      'username',
    ]) {
      expect(
        () => assertNoPii('x', {key: 'v'}),
        throwsStateError,
        reason: '$key would reach the analytics provider',
      );
    }
  });

  test('case does not matter — keys arrive in any casing', () {
    expect(() => assertNoPii('x', {'Email': 'a'}), throwsStateError);
    expect(() => assertNoPii('x', {'PASSWORD': 'a'}), throwsStateError);
    expect(() => assertNoPii('x', {'userEmail': 'a'}), throwsStateError);
  });

  test('⚠️ a separator inside the word defeats it — and that is the limit', () {
    // المطابقةُ بالاحتواء على النصّ بحروفٍ صغيرة، فـ`e-mail` و`e_mail` **تمرّان**:
    // لا يحتويان `email`. وهو حدٌّ مقبول لحارسٍ بـ`assert` — والبديلُ تطبيعُ
    // الفواصل، وهو يُسقط مفاتيحَ سليمة (`phone_book` مثلاً لا علاقة له بهاتف).
    //
    // **ويُسجَّل لأن من يراه يظنّه شاملاً.** ومفتاحٌ كهذا يُضاف إلى الجرد صريحاً.
    expect(() => assertNoPii('x', {'e-mail': 'a'}), returnsNormally);
  });

  test('null and numbers are not mistaken for text', () {
    expect(() => assertNoPii('x', null), returnsNormally);
    expect(() => assertNoPii('x', {'count': 3}), returnsNormally);
  });
}
