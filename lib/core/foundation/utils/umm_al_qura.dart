import 'package:app_template/core/foundation/utils/umm_al_qura_data.dart';

/// A Hijri date. Field order follows the source's `[day, month, year]`.
class HijriDate {
  const HijriDate(this.day, this.month, this.year);

  final int day;
  final int month;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.day == day &&
      other.month == month &&
      other.year == year;

  @override
  int get hashCode => Object.hash(day, month, year);

  @override
  String toString() => '$day/$month/$year';
}

/// The official **Umm al-Qura** conversion — `@tabby_ai/hijri-converter`'s
/// `gregorianToHijri`, ported with its **literal month-start table**
/// ([kUmmAlQuraMonthStarts]). The Dart `hijri` package's tabular arithmetic
/// differs from it on 90 days in its range (2006, Dec 2024, 2063).
///
/// The Hijri date depends on the Gregorian date only: it changes at
/// **midnight** local time, not at sunset.
abstract final class UmmAlQura {
  /// `Hijri.fromGregorian`'s supported range (1 Aug 1924 … 16 Nov 2077).
  static bool inRange(int year, int month, int day) {
    int iso(List<int> d) => d[0] * 10000 + d[1] * 100 + d[2];
    final v = year * 10000 + month * 100 + day;
    return v >= iso(kUmmAlQuraGregorianMin) && v <= iso(kUmmAlQuraGregorianMax);
  }

  /// Throws [RangeError] outside [inRange] — use `HijriDateX.tryToHijri` where
  /// a date can fall outside.
  static HijriDate fromGregorian(int year, int month, int day) {
    if (!inRange(year, month, day)) {
      throw RangeError(
        'Gregorian $year-$month-$day outside the Umm al-Qura table',
      );
    }
    final rjd = _gregorianToJulian(year, month, day) - 2400000;
    final index = _bisectRight(kUmmAlQuraMonthStarts, rjd) - 1;
    final months = index + kUmmAlQuraHijriOffset;
    final years = months ~/ 12;
    return HijriDate(
      rjd - kUmmAlQuraMonthStarts[index] + 1,
      months - years * 12 + 1,
      years + 1,
    );
  }

  /// The user's ± days on a Hijri date (moon sighting differs by country).
  /// Assumes 30 days per month — it can yield the 30th of a 29-day month — and
  /// carries once, so keep [offset] within ±29.
  static HijriDate adjust(HijriDate h, int offset) {
    var day = h.day + offset;
    var month = h.month;
    var year = h.year;
    if (day > 30) {
      day -= 30;
      month += 1;
    }
    if (day < 1) {
      day += 30;
      month -= 1;
    }
    if (month > 12) {
      month -= 12;
      year += 1;
    }
    if (month < 1) {
      month += 12;
      year -= 1;
    }
    return HijriDate(day, month, year);
  }

  static const _daysBeforeMonth = [
    0,
    0,
    31,
    59,
    90,
    120,
    151,
    181,
    212,
    243,
    273,
    304,
    334,
  ];

  static bool _isLeap(int y) => y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);

  /// `gregorianToJulian` (`dateHelpersHijri.js`).
  static int _gregorianToJulian(int year, int month, int day) {
    final y = year - 1;
    final daysBeforeYear = y * 365 + y ~/ 4 - y ~/ 100 + y ~/ 400;
    final daysBeforeMonth =
        _daysBeforeMonth[month] + (month > 2 && _isLeap(year) ? 1 : 0);
    return daysBeforeYear + daysBeforeMonth + day + 1721425;
  }

  static int _bisectRight(List<int> a, int x) {
    var lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (x < a[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }
}
