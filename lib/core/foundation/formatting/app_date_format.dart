import 'package:app_template/core/foundation/utils/arabic_digits.dart';
import 'package:app_template/core/foundation/utils/calendar_names.dart';
import 'package:app_template/core/foundation/utils/hijri_date_extension.dart';
import 'package:app_template/core/foundation/utils/umm_al_qura.dart';

/// Which calendar a date is written in.
enum DateCalendar { gregorian, hijri }

/// Which month names: each is a list in [CalendarNames], Arabic and English.
enum MonthNames {
  /// كانون الثاني… / January… (English per [AppDateFormat.englishMonths]).
  levant,

  /// يناير… / January… — `Intl` `ar` (English per [AppDateFormat.englishMonths]).
  gregorian,

  /// ربيع الآخر… — [CalendarNames.hijriMonthsAr].
  hijri,

  /// ربيع الثاني… — [CalendarNames.hijriMonthsAltAr].
  hijriAlt,
}

/// What joins the weekday to the date.
enum WeekdayJoin {
  /// «الخميس، 22 …» / "Thursday, 22 …".
  comma,

  /// «الخميس 22 …» in Arabic; still "Thursday, …" in English.
  spaceInArabic,
}

/// The era marker after a Hijri year.
enum EraMarker {
  none,

  /// « هـ» / " H".
  both,

  /// « هـ» in Arabic only.
  arabicOnly,
}

/// English month names. Arabic names have no short form in use.
enum EnglishMonths {
  /// January…
  full,

  /// Jan… Sep… — `en-US` `MMM`.
  short,

  /// Jan… Sept… — `en-GB` `month: short`.
  shortGb,
}

/// Arabic text's digits. English text is always Latin.
enum ArabicDigits {
  /// 1448 — what `Intl.NumberFormat("ar")` writes.
  latin,

  /// ١٤٤٨ — what regional date formatters (`ar-SY`, `ar-SA`) write.
  indic,
}

/// **A date shape**, made of parts — the middle of three steps
/// (`readme/06_CAPABILITIES.md` §التاريخ): the materials ([CalendarNames],
/// [HijriDateX], [toArabicIndicDigits]) below, the named catalog
/// (`AppDateFormats`) above, and a screen only ever names a catalog entry.
///
/// Pure Dart: notifications and other UI-less texts call [apply]; the UI goes
/// through `AppDateText.format(date, format: …)`.
class AppDateFormat {
  const AppDateFormat({
    required this.calendar,
    required this.months,
    this.weekday = false,
    this.weekdayJoin = WeekdayJoin.comma,
    this.year = true,
    this.era = EraMarker.none,
    this.digits = ArabicDigits.latin,
    this.englishMonthFirst = false,
    this.englishMonths = EnglishMonths.full,
  });

  final DateCalendar calendar;
  final MonthNames months;
  final bool weekday;
  final WeekdayJoin weekdayJoin;
  final bool year;
  final EraMarker era;
  final ArabicDigits digits;

  /// "October 28, 2026" (`en-US`) instead of "28 October 2026".
  final bool englishMonthFirst;

  /// Gregorian English month names (Hijri names have one form).
  final EnglishMonths englishMonths;

  /// The calendar day of [date] (its `year`/`month`/`day` as they stand). A
  /// Hijri format converts it with the user's [hijriAdjustment].
  String apply(
    DateTime date, {
    required String language,
    int hijriAdjustment = 0,
  }) => switch (calendar) {
    DateCalendar.gregorian => _render(
      date.day,
      date.month,
      date.year,
      date.weekday,
      language,
    ),
    DateCalendar.hijri => applyHijri(
      date.toHijri(adjustment: hijriAdjustment),
      date.weekday,
      language: language,
    ),
  };

  /// A Hijri date already converted (a server or cache may carry one), with
  /// its Gregorian [weekday] (ISO, Monday = 1; ignored when the format shows
  /// none). Empty for an invalid month.
  String applyHijri(HijriDate h, int weekday, {required String language}) {
    if (h.month < 1 || h.month > 12) return '';
    return _render(h.day, h.month, h.year, weekday, language);
  }

  String _render(int day, int month, int y, int weekdayIso, String language) {
    if (weekday && (weekdayIso < 1 || weekdayIso > 7)) return '';
    final arabic = language == 'ar';
    final name = _monthList(arabic)[month - 1];
    final buffer = StringBuffer();
    if (weekday) {
      buffer
        ..write(CalendarNames.weekday(weekdayIso, arabic: arabic))
        ..write(
          arabic ? (weekdayJoin == WeekdayJoin.comma ? '، ' : ' ') : ', ',
        );
    }
    if (!arabic && englishMonthFirst) {
      buffer.write('$name $day');
      if (year) buffer.write(', $y');
    } else {
      buffer.write('$day $name');
      if (year) buffer.write(' $y');
    }
    if (year &&
        (era == EraMarker.both || (era == EraMarker.arabicOnly && arabic))) {
      buffer.write(arabic ? ' هـ' : ' H');
    }
    final text = buffer.toString();
    return arabic && digits == ArabicDigits.indic
        ? toArabicIndicDigits(text)
        : text;
  }

  List<String> get _english => switch (englishMonths) {
    EnglishMonths.full => CalendarNames.gregorianMonthsEn,
    EnglishMonths.short => CalendarNames.gregorianMonthsEnShort,
    EnglishMonths.shortGb => CalendarNames.gregorianMonthsEnShortGb,
  };

  List<String> _monthList(bool arabic) => switch (months) {
    MonthNames.levant =>
      arabic ? CalendarNames.gregorianMonthsLevantAr : _english,
    MonthNames.gregorian => arabic ? CalendarNames.gregorianMonthsAr : _english,
    MonthNames.hijri =>
      arabic ? CalendarNames.hijriMonthsAr : CalendarNames.hijriMonthsEn,
    MonthNames.hijriAlt =>
      arabic ? CalendarNames.hijriMonthsAltAr : CalendarNames.hijriMonthsAltEn,
  };
}
