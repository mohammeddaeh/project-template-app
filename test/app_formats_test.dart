import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/core/foundation/utils/arabic_digits.dart';

/// The shapes and the starter catalog, both languages, pinned. A change to a
/// shape is a change to its line here — deliberately visible in review. That
/// screens pick a shape by name and never build one is `check_structure` C17.
void main() {
  // Wednesday 28 October 2026 = 17 Jumada al-Awwal 1448 (Umm al-Qura).
  final day = DateTime(2026, 10, 28);

  String ar(AppDateFormat f) => f.apply(day, language: 'ar');
  String en(AppDateFormat f) => f.apply(day, language: 'en');

  test('toArabicIndicDigits converts digits and keeps everything else', () {
    expect(toArabicIndicDigits('12:05 PM 1448'), '١٢:٠٥ PM ١٤٤٨');
    expect(toArabicIndicDigits('بلا أرقام'), 'بلا أرقام');
  });

  test('the starter catalog', () {
    expect(ar(AppDateFormats.listDate), '٢٨ أكتوبر ٢٠٢٦');
    expect(en(AppDateFormats.listDate), '28 October 2026');
    expect(ar(AppDateFormats.detailHijri), 'الأربعاء، 17 جمادى الأولى 1448 هـ');
    expect(
      en(AppDateFormats.detailHijri),
      'Wednesday, 17 Jumada al-Awwal 1448 H',
    );
    expect(AppTimeFormats.listTime.apply(17, 26, language: 'ar'), '5:26 م');
    expect(AppNumberFormats.count.apply(1234, language: 'ar'), '1,234');
    expect(AppNumberFormats.countdown.apply(3912), '01:05:12');
  });

  group('AppDateFormat parts', () {
    test('month spellings', () {
      const levant = AppDateFormat(
        calendar: DateCalendar.gregorian,
        months: MonthNames.levant,
      );
      expect(ar(levant), '28 تشرين الأول 2026');
      const alt = AppDateFormat(
        calendar: DateCalendar.hijri,
        months: MonthNames.hijriAlt,
        year: false,
      );
      expect(
        alt.apply(DateTime(2026, 9, 25), language: 'ar'),
        '14 ربيع الثاني',
      );
      expect(
        alt.apply(DateTime(2026, 9, 25), language: 'en'),
        "14 Rabi' al-Thani",
      );
    });

    test('weekday join, era and English month order and length', () {
      const spaced = AppDateFormat(
        calendar: DateCalendar.hijri,
        months: MonthNames.hijri,
        weekday: true,
        weekdayJoin: WeekdayJoin.spaceInArabic,
        era: EraMarker.arabicOnly,
      );
      expect(ar(spaced), 'الأربعاء 17 جمادى الأولى 1448 هـ');
      expect(en(spaced), 'Wednesday, 17 Jumada al-Awwal 1448');

      const usShort = AppDateFormat(
        calendar: DateCalendar.gregorian,
        months: MonthNames.gregorian,
        englishMonthFirst: true,
        englishMonths: EnglishMonths.short,
      );
      expect(
        usShort.apply(DateTime(2026, 9, 28), language: 'en'),
        'Sep 28, 2026',
      );
      const gbShort = AppDateFormat(
        calendar: DateCalendar.gregorian,
        months: MonthNames.gregorian,
        englishMonths: EnglishMonths.shortGb,
      );
      expect(
        gbShort.apply(DateTime(2026, 9, 28), language: 'en'),
        '28 Sept 2026',
      );
    });

    test('a Hijri adjustment reaches the text', () {
      expect(
        AppDateFormats.detailHijri.apply(
          day,
          language: 'en',
          hijriAdjustment: 1,
        ),
        'Wednesday, 18 Jumada al-Awwal 1448 H',
      );
    });
  });

  test('AppTimeFormat parts', () {
    const padded = AppTimeFormat(padTwelveHour: true);
    expect(padded.apply(17, 50, language: 'ar'), '05:50');
    expect(padded.apply(17, 50, language: 'ar', h24: true), '17:50');

    const indic = AppTimeFormat(suffix: true, digits: ArabicDigits.indic);
    expect(indic.apply(19, 30, language: 'ar'), '٧:٣٠ م');
    expect(indic.apply(19, 30, language: 'en'), '7:30 PM');

    const twelve = AppTimeFormat(clock: TimeClock.twelve, suffix: true);
    expect(twelve.apply(19, 30, language: 'ar', h24: true), '7:30 م');
    expect(twelve.apply(0, 0, language: 'en'), '12:00 AM');
  });

  test('number, distance and countdown parts', () {
    expect(
      const AppNumberFormat(grouping: false).apply(1234, language: 'ar'),
      '1234',
    );
    expect(
      const AppNumberFormat(
        digits: ArabicDigits.indic,
      ).apply(-1234, language: 'ar'),
      '-١,٢٣٤',
    );

    final near = AppNumberFormats.distance.apply(0.174)!;
    expect([near.value, near.meters], ['174', true]);
    final far = const AppDistanceFormat(approximate: true).apply(1.06)!;
    expect([far.value, far.meters], ['≈ 1.1', false]);
    expect(AppNumberFormats.distance.apply(0), isNull);

    expect(const AppDurationFormat(hours: false).apply(75 * 60 + 5), '75:05');
  });
}
