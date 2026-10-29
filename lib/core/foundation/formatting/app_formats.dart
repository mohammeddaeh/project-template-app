import 'package:app_template/core/foundation/formatting/app_date_format.dart';
import 'package:app_template/core/foundation/formatting/app_number_format.dart';
import 'package:app_template/core/foundation/formatting/app_time_format.dart';

export 'app_date_format.dart';
export 'app_number_format.dart';
export 'app_time_format.dart';

/// **Every date shape the app shows**, by name — the one file to read or edit.
///
/// - Change how a date looks everywhere it is used: edit its line here.
/// - A new shape: a new line here, then its name at the screen.
/// - A screen that should show another shape: change the name it picks.
///
/// Name an entry after **where it is shown**, not after how it looks: two
/// screens that share a look today get two names, so changing one never
/// moves the other. The entries below are a starting set — the project owns
/// this file and replaces them with its own.
abstract final class AppDateFormats {
  /// A Gregorian date in a list row: «٢٨ أكتوبر ٢٠٢٦» / "28 October 2026".
  static const listDate = AppDateFormat(
    calendar: DateCalendar.gregorian,
    months: MonthNames.gregorian,
    digits: ArabicDigits.indic,
  );

  /// A Hijri date with its weekday and era on a detail screen:
  /// «الأربعاء، 17 جمادى الأولى 1448 هـ» / "Wednesday, 17 Jumada al-Awwal 1448 H".
  static const detailHijri = AppDateFormat(
    calendar: DateCalendar.hijri,
    months: MonthNames.hijri,
    weekday: true,
    era: EraMarker.both,
  );
}

/// **Every time shape the app shows**, by name — see [AppDateFormats].
abstract final class AppTimeFormats {
  /// The user's 12/24 choice, `5:26 م` on the 12-hour clock.
  static const listTime = AppTimeFormat(suffix: true);
}

/// **Every count, distance and countdown shape**, by name — see [AppDateFormats].
abstract final class AppNumberFormats {
  /// A count with grouping: `1,234`.
  static const count = AppNumberFormat();

  /// A distance: `850` metres or `2.4` km — the unit word is the caller's key.
  static const distance = AppDistanceFormat();

  /// A countdown: `01:05:12`.
  static const countdown = AppDurationFormat();
}
