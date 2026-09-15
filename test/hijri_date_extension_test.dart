import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/foundation/utils/hijri_date_extension.dart';

void main() {
  group('HijriDateX', () {
    // مرجعٌ من مجموعة اختبارات حزمة hijri نفسها — لا حساب يدويّ عرضة للخطأ.
    // ٢٠ مايو ٢٠٢٠ ⇔ ٢٧ رمضان ١٤٤١.
    final reference = DateTime(2020, 5, 20);

    test('toHijri converts to the exact known year/month/day', () {
      final hijri = reference.toHijri();
      expect(hijri.hYear, 1441);
      expect(hijri.hMonth, 9);
      expect(hijri.hDay, 27);
    });

    test('toHijriString (ar) contains the day and year as digits', () {
      final text = reference.toHijriString();
      expect(text, contains('27'));
      expect(text, contains('1441'));
    });

    test('toHijriString (en) names the month in English', () {
      final text = reference.toHijriString(language: 'en');
      expect(text, contains('Ramadan'));
    });

    test(
      'switching language between calls does not leak into the next call',
      () {
        // `HijriCalendar.language` ثابتٌ عامّ — هذا الاختبار يحرس بالضبط
        // العطل الذي حذّر منه تعليق الملف: نداءٌ بلغةٍ يجب ألّا يغيّر نتيجة
        // النداء التالي بلغةٍ أخرى على نفس التاريخ.
        final arabic = reference.toHijriString(language: 'ar');
        final english = reference.toHijriString(language: 'en');
        final arabicAgain = reference.toHijriString(language: 'ar');
        expect(arabicAgain, arabic);
        expect(english, isNot(equals(arabic)));
      },
    );
  });
}
