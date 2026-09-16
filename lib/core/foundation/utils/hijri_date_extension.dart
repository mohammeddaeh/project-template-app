import 'package:hijri/hijri_calendar.dart';

/// تحويل ميلاديّ ← هجريّ — حزمة `hijri` وحدها، بلا حالة تطبيق ولا `BuildContext`.
///
/// ⚠️ **`HijriCalendar.language` ثابتٌ عامٌّ (`static`) لا نسخيّ** — الحزمة
/// تقرأه وقت `HijriCalendar.fromDate()` نفسِه لتحديد أسماء الأشهر، فيجب
/// ضبطه **قبل** كل استدعاء لا مرّةً عند الإقلاع، وإلا بقيت النتيجة بلغة آخر
/// نداءٍ من أي مكانٍ بالتطبيق. لهذا كل دالّةٍ هنا تأخذ [language] صراحةً
/// وتضبطه بنفسها — لا قراءة `context.locale` مباشرةً هنا (`foundation/` لا
/// تعرف Flutter أصلاً)؛ تلك مسؤولية الطبقة التي تستدعيها (`AppDateText`).
extension HijriDateX on DateTime {
  /// [language] — `'ar'` أو `'en'` (القيمتان اللتان تدعمهما الحزمة افتراضياً).
  HijriCalendar toHijri({String language = 'ar'}) {
    HijriCalendar.language = language;
    return HijriCalendar.fromDate(this);
  }

  /// مثال: `١٥ رجب ١٤٤٦` (`ar`) أو `15 Rajab 1446` (`en`).
  String toHijriString({String language = 'ar'}) {
    final hijri = toHijri(language: language);
    return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
  }
}
