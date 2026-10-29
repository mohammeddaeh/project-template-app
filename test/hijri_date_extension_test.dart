import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/foundation/utils/hijri_date_extension.dart';
import 'package:app_template/core/foundation/utils/umm_al_qura.dart';

void main() {
  group('HijriDateX (Umm al-Qura)', () {
    // ٢٠ مايو ٢٠٢٠ ⇔ ٢٧ رمضان ١٤٤١ (تقويم أم القرى).
    final reference = DateTime(2020, 5, 20);

    test('toHijri converts to the exact known year/month/day', () {
      expect(reference.toHijri(), const HijriDate(27, 9, 1441));
      // الأربعاء ٢٨ أكتوبر ٢٠٢٦ ⇔ ١٧ جمادى الأولى ١٤٤٨.
      expect(DateTime(2026, 10, 28).toHijri(), const HijriDate(17, 5, 1448));
    });

    test('adjustment moves the Hijri day, carrying across a month', () {
      expect(reference.toHijri(adjustment: 1), const HijriDate(28, 9, 1441));
      expect(
        DateTime(2026, 10, 28).toHijri(adjustment: -17),
        const HijriDate(30, 4, 1448),
      );
    });

    test('toHijriString names the month in the requested language', () {
      expect(reference.toHijriString(), '27 رمضان 1441');
      expect(reference.toHijriString(language: 'en'), '27 Ramadan 1441');
    });

    test('the language is an argument, not shared state', () {
      final arabic = reference.toHijriString(language: 'ar');
      reference.toHijriString(language: 'en');
      expect(reference.toHijriString(language: 'ar'), arabic);
    });

    test('tryToHijri is null outside the table, toHijri throws', () {
      expect(DateTime(1900).tryToHijri(), isNull);
      expect(() => DateTime(1900).toHijri(), throwsRangeError);
      expect(DateTime(2077, 11, 16).tryToHijri(), isNotNull);
      expect(DateTime(2077, 11, 17).tryToHijri(), isNull);
    });
  });
}
