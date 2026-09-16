import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/dates/app_date_text.dart';

/// `language` هنا **دائماً** صريح (`arabic`/`english`) لا `auto` — `auto`
/// يقرأ `context.isAr` عبر `BuildContext.locale` من `EasyLocalization`، وهذا
/// المستودع لا يركّب `EasyLocalization` بأي اختبار (راجع التعليق بـ
/// `test/error_boundary_test.dart`: يحتاج `SharedPreferences` عبر قناة منصّة
/// بلا محاكاة، وتعليقٌ حقيقيّ >180 ثانية وقع فعلاً قبل هذا القرار).
void main() {
  // مرجعٌ من مجموعة اختبارات حزمة `hijri` نفسها (نفس `hijri_date_extension_test.dart`):
  // ٢٠ مايو ٢٠٢٠ ⇔ ٢٧ رمضان ١٤٤١.
  final reference = DateTime(2020, 5, 20);

  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  Widget host(Widget child) => MaterialApp(
    theme: AppThemeData.light(const Locale('ar'), AppFonts.available.first),
    home: Scaffold(body: child),
  );

  String textOf(WidgetTester tester, Finder finder) =>
      tester.widget<Text>(finder).data ?? '';

  group('single calendar', () {
    testWidgets('hijri, Arabic, full name → month name + eastern digits', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppDateText(reference, language: AppDateLanguage.arabic)),
      );
      final text = textOf(tester, find.byType(Text));
      expect(text, contains('رمضان'));
      expect(text, contains('٢٧')); // اللغة العربية ⇒ أرقام شرقية تلقائياً
      expect(text, contains('١٤٤١'));
      expect(text, isNot(contains('27')));
    });

    testWidgets('hijri, English, full name → English month name + western digits', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppDateText(reference, language: AppDateLanguage.english)),
      );
      final text = textOf(tester, find.byType(Text));
      expect(text, contains('Ramadan'));
      expect(text, contains('27'));
      expect(text, contains('1441'));
    });

    testWidgets('gregorian, numeric month, custom separator', (tester) async {
      await tester.pumpWidget(
        host(
          AppDateText(
            reference,
            calendar: AppDateCalendar.gregorian,
            language: AppDateLanguage.english,
            monthFormat: AppDateMonthFormat.numeric,
            partSeparator: '-',
          ),
        ),
      );
      expect(textOf(tester, find.byType(Text)), '20-05-2020');
    });

    testWidgets('gregorian, full name, English', (tester) async {
      await tester.pumpWidget(
        host(
          AppDateText(
            reference,
            calendar: AppDateCalendar.gregorian,
            language: AppDateLanguage.english,
          ),
        ),
      );
      final text = textOf(tester, find.byType(Text));
      expect(text, contains('May'));
      expect(text, contains('2020'));
    });

    testWidgets('gregorian, short month name', (tester) async {
      await tester.pumpWidget(
        host(
          AppDateText(
            reference,
            calendar: AppDateCalendar.gregorian,
            language: AppDateLanguage.english,
            monthFormat: AppDateMonthFormat.nameShort,
          ),
        ),
      );
      expect(textOf(tester, find.byType(Text)), contains('May'));
    });
  });

  group('both calendars', () {
    testWidgets('stacked layout renders two Text widgets, hijri first', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          AppDateText(
            reference,
            calendar: AppDateCalendar.both,
            language: AppDateLanguage.english,
          ),
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts, hasLength(2));
      expect(texts[0].data, contains('Ramadan'));
      expect(texts[1].data, contains('May'));
    });

    testWidgets('inline layout renders a single non-clipping Text.rich with the separator', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          AppDateText(
            reference,
            calendar: AppDateCalendar.both,
            layout: AppDateLayout.inline,
            language: AppDateLanguage.english,
            calendarSeparator: ' | ',
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      final richText = tester.widget<Text>(find.byType(Text));
      final plain = richText.textSpan!.toPlainText();
      expect(plain, contains('Ramadan'));
      expect(plain, contains('May'));
      expect(plain, contains(' | '));
      // لا `maxLines` ولا `overflow: ellipsis` — النصّ يتمدّد بحرّية.
      expect(richText.maxLines, isNull);
      expect(richText.overflow, isNull);
    });
  });
}
