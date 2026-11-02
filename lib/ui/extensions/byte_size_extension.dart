import 'package:easy_localization/easy_localization.dart';

import 'package:app_template/resources/locale_keys.g.dart';

/// حجمُ ملفٍّ **بلغة المستخدم**.
///
/// ```dart
/// 2516582.asFileSize   // «٢٫٤ ميغابايت»  ·  "2.4 MB"
/// ```
///
/// ## لماذا امتدادٌ عام لا دالّة خاصّة بشاشة
///
/// `'KB'` و`'MB'` المكتوبتان بيد كلِّ شاشة **نصٌّ لاتينيٌّ جامد** وسط واجهةٍ
/// عربية، وهي حالةٌ يمنعها `lib/CLAUDE.md` صراحةً — وتمرّ لأنها وحدةُ قياسٍ لا
/// «نصّ» بالنظر السريع. ودالّتان بشاشتين تعني مقياسَين لنفس الشيء.
///
/// ## والكسر عشريٌّ واحد لا أكثر
///
/// «٢٫٤ ميغابايت» تُقرأ بلمحة، و«٢٫٣٩٩٨ ميغابايت» دقّةٌ لا يستعملها أحد وتُزاحم
/// رقم العنصر على السطر نفسه. وما دون الميغابايت يُقرَّب لأعلى: ملفٌّ بـ٢٠٠
/// بايت ليس «٠ كيلوبايت» — الصفر يُقرأ «فارغ»، وهو أسوأ من تقريبٍ بواحد.
extension ByteSizeExtension on int {
  static const _kilobyte = 1024;
  static const _megabyte = 1024 * 1024;

  /// نصٌّ فارغ لغير الموجب: صفرٌ أو سالب يعني «لا حجم يُعرف»، وسطرٌ يقول
  /// «٠ كيلوبايت» يصف ملفاً فارغاً — وهو ادّعاءٌ لا مصدر له.
  String get asFileSize {
    if (this <= 0) return '';
    if (this < _megabyte) {
      return LocaleKeys.unitKilobyte.tr(args: ['${(this / _kilobyte).ceil()}']);
    }
    return LocaleKeys.unitMegabyte.tr(
      args: [(this / _megabyte).toStringAsFixed(1)],
    );
  }
}
