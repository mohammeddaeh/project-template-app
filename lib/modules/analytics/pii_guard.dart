/// Debug-only guard against sending personally identifiable data to
/// analytics — email, password, tokens, phone numbers, national IDs, and
/// usernames must never leave this device through an analytics event.
///
/// Pure Dart, no Firebase — safe to unit test directly. Call sites wrap it in
/// `assert()` so the check (and the string work it does) is compiled out of
/// release builds entirely; it only ever throws during development.
///
/// ```dart
/// assert(() { assertNoPii('track:$name', params); return true; }());
/// ```
/// **الجردُ — ويُطابَق بالاحتواء على النصّ بحروفٍ صغيرة.**
///
/// فـ`userEmail` و`PASSWORD` و`user_email_hash` كلُّها تُمسَك.
///
/// ⚠️ **وحدُّه أن فاصلاً داخل الكلمة يُفلته**: `e-mail` و`e_mail` لا يحتويان
/// `email`. والبديلُ تطبيعُ الفواصل، وهو يُسقط مفاتيحَ سليمة (`phone_book`).
/// فمفتاحٌ كهذا **يُضاف إلى الجرد صريحاً** — و`test/pii_guard_test.dart` يسجّل
/// الحدَّ باختبارٍ باسمه كي لا يُظنَّ الحارسُ شاملاً.
const _bannedKeywords = [
  'email',
  'password',
  'token',
  'phone',
  'national_id',
  'nationalid',
  'username',
];

void assertNoPii(String context, Object? value) {
  final offender = _findBannedKeyword(value);
  if (offender != null) {
    throw StateError(
      'Analytics PII guard: "$context" contains a banned field ("$offender"). '
      'Never send email, password, tokens, phone numbers, national IDs or '
      'usernames to analytics.',
    );
  }
}

String? _findBannedKeyword(Object? value) {
  switch (value) {
    case Map<dynamic, dynamic>():
      for (final entry in value.entries) {
        final keyHit = _matchBannedKeyword(entry.key.toString());
        if (keyHit != null) return keyHit;
        final valueHit = _findBannedKeyword(entry.value);
        if (valueHit != null) return valueHit;
      }
      return null;
    case String():
      return _matchBannedKeyword(value);
    default:
      return null;
  }
}

String? _matchBannedKeyword(String text) {
  final lower = text.toLowerCase();
  for (final keyword in _bannedKeywords) {
    if (lower.contains(keyword)) return keyword;
  }
  return null;
}
