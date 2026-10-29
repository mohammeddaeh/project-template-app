import 'package:app_template/core/foundation/formatting/app_date_format.dart';
import 'package:app_template/core/foundation/utils/arabic_digits.dart';

/// Which clock a time is written on.
enum TimeClock {
  /// The user's 12/24 choice, passed to [AppTimeFormat.apply].
  preference,

  /// Always 12 hours, whatever the setting.
  twelve,
}

/// **A time shape**, made of parts — see `AppDateFormat`; the catalog is
/// `AppTimeFormats`. A 24-hour time is always `HH:mm`.
class AppTimeFormat {
  const AppTimeFormat({
    this.clock = TimeClock.preference,
    this.padTwelveHour = false,
    this.suffix = false,
    this.digits = ArabicDigits.latin,
  });

  final TimeClock clock;

  /// `05:26` rather than `5:26` on the 12-hour clock.
  final bool padTwelveHour;

  /// « ص»/« م» in Arabic, " AM"/" PM" in English, on the 12-hour clock.
  final bool suffix;

  final ArabicDigits digits;

  /// [hour] 0–23, [minute] 0–59.
  String apply(
    int hour,
    int minute, {
    required String language,
    bool h24 = false,
  }) {
    final arabic = language == 'ar';
    final mm = minute.toString().padLeft(2, '0');
    final String text;
    if (h24 && clock == TimeClock.preference) {
      text = '${hour.toString().padLeft(2, '0')}:$mm';
    } else {
      final h = hour % 12 == 0 ? 12 : hour % 12;
      final hh = padTwelveHour ? h.toString().padLeft(2, '0') : '$h';
      final pm = hour >= 12;
      final tail = suffix
          ? ' ${arabic ? (pm ? 'م' : 'ص') : (pm ? 'PM' : 'AM')}'
          : '';
      text = '$hh:$mm$tail';
    }
    return arabic && digits == ArabicDigits.indic
        ? toArabicIndicDigits(text)
        : text;
  }
}
