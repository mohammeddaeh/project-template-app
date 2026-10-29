import 'package:app_template/core/foundation/utils/calendar_names.dart';
import 'package:app_template/core/foundation/utils/umm_al_qura.dart';

/// Gregorian → Hijri for the whole app, on the **official Umm al-Qura**
/// table ([UmmAlQura]). Pure Dart, no global state: the language is an
/// argument, never a static set before each call.
///
/// The calendar day of the [DateTime] is converted as it stands (its
/// `year`/`month`/`day`); the Hijri date changes at midnight, not sunset.
/// [toHijri] throws [RangeError] outside 1 Aug 1924 … 16 Nov 2077
/// ([UmmAlQura.inRange]); [tryToHijri] returns `null` there.
extension HijriDateX on DateTime {
  /// [adjustment] is the user's ± days — moon sighting differs by country.
  HijriDate toHijri({int adjustment = 0}) {
    final h = UmmAlQura.fromGregorian(year, month, day);
    return adjustment == 0 ? h : UmmAlQura.adjust(h, adjustment);
  }

  /// [toHijri], or `null` outside the table's range.
  HijriDate? tryToHijri({int adjustment = 0}) =>
      UmmAlQura.inRange(year, month, day)
      ? toHijri(adjustment: adjustment)
      : null;

  /// `27 رمضان 1441` / `27 Ramadan 1441` — Latin digits; the caller decides
  /// on Arabic-Indic (`AppDateText` does, by language).
  String toHijriString({String language = 'ar'}) {
    final h = toHijri();
    final months = language == 'ar'
        ? CalendarNames.hijriMonthsAr
        : CalendarNames.hijriMonthsEn;
    return '${h.day} ${months[h.month - 1]} ${h.year}';
  }
}
