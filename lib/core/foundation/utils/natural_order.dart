/// **مقارنةٌ طبيعية لمعرّفاتٍ مرقّمة** — «٩١/٢» بعد «٩١/١» وقبل «٩١/١٠».
///
/// ## لماذا بـ`foundation/` لا بشريحة
///
/// وُلدت داخل cubit خاصّةً به، ثم صار لكيانٍ ثانٍ رقمٌ نصّيٌّ هو الآخر
/// فاحتاجها — و`features → features ❌` تمنع الاستيراد
/// بينهما. والنسخُ كان يعني **نسختين من قاعدة ترتيبٍ واحدة**: تُشدَّد إحداهما
/// يوماً ولا تُشدَّد الأخرى، فتُرتَّب شاشتان بمنطقين ولا يُخفق شيء (R34).
///
/// وهي Dart خالص بلا Flutter ولا شبكة — فموضعها `foundation/` بالضبط.
///
/// ## القاعدة
///
/// مقارنةُ النصّ الخام لا تصلح: `'1247/12'` تسبق `'331'` حرفياً لأن `'1'` قبل
/// `'3'`. فتُقسَّم السلسلة إلى مقاطعِ أرقامٍ وغيرِها، ويُقارَن الرقمُ رقماً
/// والنصُّ نصّاً.
///
/// و`'أ'` وأشباهُه تُقارَن نصّاً كما هي — فرقمٌ يسبق حرفاً، وهو الترتيب الذي
/// يتوقّعه من يقرأ قائمةً مرقّمة.
abstract final class NaturalOrder {
  static int compare(String a, String b) {
    final left = _chunks(a);
    final right = _chunks(b);
    for (var i = 0; i < left.length && i < right.length; i++) {
      final x = left[i];
      final y = right[i];
      final xn = int.tryParse(x);
      final yn = int.tryParse(y);
      final order = (xn != null && yn != null)
          ? xn.compareTo(yn)
          : x.compareTo(y);
      if (order != 0) return order;
    }
    return left.length.compareTo(right.length);
  }

  /// `'91/10'` ⇒ `['91', '/', '10']`
  static List<String> _chunks(String value) =>
      RegExp(r'\d+|\D+').allMatches(value).map((m) => m[0]!).toList();
}
