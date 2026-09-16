import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_template/core/foundation/utils/hijri_date_extension.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/ui/extensions/extensions.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  AppDateText — عرض التاريخ **الوحيد** بالتطبيق: هجريّ · ميلاديّ · أو الاثنان
/// ═══════════════════════════════════════════════════════════════════════════
///
/// ## الأشكال
///
/// ```dart
/// // هجريّ وحده — الافتراضي، بديل `toHijriString` القديم
/// AppDateText(entity.createdAt)
///
/// // ميلاديّ وحده
/// AppDateText(entity.createdAt, calendar: AppDateCalendar.gregorian)
///
/// // الاثنان معاً، كلٌّ بسطره
/// AppDateText(entity.createdAt, calendar: AppDateCalendar.both)
///
/// // الاثنان معاً بسطرٍ واحد — لا قطع نصّ أبداً، يتمدّد ويلتفّ عند الحاجة
/// AppDateText(
///   entity.createdAt,
///   calendar: AppDateCalendar.both,
///   layout: AppDateLayout.inline,
/// )
///
/// // رقماً صرفاً، بفاصلة مخصّصة — لجدول أو تصدير
/// AppDateText(
///   entity.createdAt,
///   monthFormat: AppDateMonthFormat.numeric,
///   partSeparator: '-',
/// )
/// ```
///
/// | المحور | الخيارات | الوسيط |
/// |---|---|---|
/// | أيّ تقويم | هجريّ · ميلاديّ · الاثنان | [calendar] |
/// | تخطيط التقويمين (عند الاثنين) | فوق بعضٍ (`stacked`) · جنباً لجنب بلا قطع (`inline`) | [layout] |
/// | صيغة الشهر | رقماً · اسماً مختصراً · اسماً كاملاً | [monthFormat] |
/// | اللغة (والأرقام معها) | تتبع الواجهة تلقائياً · عربيّة قسراً · إنكليزية قسراً | [language] |
/// | الفاصلة بين الأرقام (بصيغة الرقم فقط) | أيّ نصّ — `/` افتراضاً | [partSeparator] |
/// | الفاصلة بين التقويمين (بتخطيط `inline` فقط) | أيّ نصّ | [calendarSeparator] |
///
/// **ولا قطع نصّ أبداً**: لا `maxLines` ولا `TextOverflow.ellipsis` بأيّ مسار
/// هنا — `inline` يبني `Text.rich` عادياً يلتفّ بحرّية.
///
/// ## عطبٌ محتمل لا يُسقط الشاشة
///
/// تحويل الهجريّ محميٌّ بـtry/catch: تاريخٌ خارج مدى حزمة `hijri` (أو أيّ عطبٍ
/// آخر بالتحويل) يُسجَّل بـ`LogService` ويُعرَض `—` بدل أن يُسقط الشاشة كاملةً
/// عبر `ErrorBoundary` العام.
class AppDateText extends StatelessWidget {
  const AppDateText(
    this.date, {
    super.key,
    this.calendar = AppDateCalendar.hijri,
    this.layout = AppDateLayout.stacked,
    this.monthFormat = AppDateMonthFormat.nameFull,
    this.language = AppDateLanguage.auto,
    this.partSeparator = '/',
    this.calendarSeparator = '  •  ',
    this.style,
  });

  /// التاريخ **الميلاديّ** دوماً — كأيّ `DateTime` بالتطبيق. التحويل الهجريّ
  /// يقع هنا داخلياً، فلا يحمل المستدعي أيّ نسخةٍ هجرية بنفسه.
  final DateTime date;

  /// أيّ تقويمٍ يُعرض.
  final AppDateCalendar calendar;

  /// تخطيط التقويمين حين [calendar] = `both`. يُهمَل غير ذلك. الهجريّ يُرسم
  /// أوّلاً دوماً.
  final AppDateLayout layout;

  /// صيغة اسم الشهر — أو رقمه.
  final AppDateMonthFormat monthFormat;

  /// لغة الأسماء والأرقام معاً — `auto` تتبع `context.isAr`. الأرقام تتبع
  /// اللغة المحلولة: شرقية (`١٢٣`) بالعربية، غربية (`123`) بالإنكليزية.
  final AppDateLanguage language;

  /// الفاصلة بين اليوم والشهر والسنة — بصيغة [AppDateMonthFormat.numeric]
  /// فقط. بصيغة الاسم يبقى الفصل مسافةً واحدة دوماً («١٥ رجب ١٤٤٦»).
  final String partSeparator;

  /// الفاصلة بين نصّي التقويمين — بتخطيط [AppDateLayout.inline] فقط.
  final String calendarSeparator;

  /// نمط النصّ. الافتراضي: `context.textTheme.bodyMedium`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedArabic = switch (language) {
      AppDateLanguage.arabic => true,
      AppDateLanguage.english => false,
      AppDateLanguage.auto => context.isAr,
    };
    final languageCode = resolvedArabic ? 'ar' : 'en';
    final effectiveStyle = style ?? context.textTheme.bodyMedium;

    final hijriText = calendar == AppDateCalendar.gregorian
        ? null
        : _buildHijri(languageCode, resolvedArabic);
    final gregorianText = calendar == AppDateCalendar.hijri
        ? null
        : _buildGregorian(languageCode, resolvedArabic);

    if (calendar != AppDateCalendar.both) {
      return Text(
        hijriText ?? gregorianText ?? '',
        style: effectiveStyle,
      );
    }

    if (layout == AppDateLayout.inline) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: hijriText, style: effectiveStyle),
            TextSpan(text: calendarSeparator, style: effectiveStyle),
            TextSpan(text: gregorianText, style: effectiveStyle),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hijriText!, style: effectiveStyle),
        const ResponsiveGap(4),
        Text(gregorianText!, style: effectiveStyle),
      ],
    );
  }

  String _buildHijri(String languageCode, bool arabicResolved) {
    try {
      final hijri = date.toHijri(language: languageCode);
      return _formatParts(
        day: hijri.hDay,
        month: hijri.hMonth,
        year: hijri.hYear,
        monthNameFull: hijri.longMonthName,
        monthNameShort: hijri.shortMonthName,
        arabicResolved: arabicResolved,
      );
    } catch (e, st) {
      LogService.error(
        'AppDateText hijri conversion failed',
        tag: 'APP_DATE_TEXT',
        error: e,
        stackTrace: st,
      );
      return '—';
    }
  }

  String _buildGregorian(String languageCode, bool arabicResolved) {
    return _formatParts(
      day: date.day,
      month: date.month,
      year: date.year,
      monthNameFull: DateFormat('MMMM', languageCode).format(date),
      monthNameShort: DateFormat('MMM', languageCode).format(date),
      arabicResolved: arabicResolved,
    );
  }

  String _formatParts({
    required int day,
    required int month,
    required int year,
    required String monthNameFull,
    required String monthNameShort,
    required bool arabicResolved,
  }) {
    final String body;
    if (monthFormat == AppDateMonthFormat.numeric) {
      final d = day.toString().padLeft(2, '0');
      final m = month.toString().padLeft(2, '0');
      body = [d, m, year.toString()].join(partSeparator);
    } else {
      final monthName = monthFormat == AppDateMonthFormat.nameFull
          ? monthNameFull
          : monthNameShort;
      body = '$day $monthName $year';
    }

    return arabicResolved ? _toEasternDigits(body) : body;
  }

  /// الأرقام الشرقية العشرة (`٠`‎–‎`٩`) — مدى `U+0660`..`U+0669` المتتالي،
  /// لا حروفٌ عربية حرفية بالكود (F13 يفحص نصّاً ظاهراً يحتاج مفتاح ترجمة؛
  /// هذه رموز أرقام لا جملة).
  static final List<String> _easternDigits = List.generate(
    10,
    (i) => String.fromCharCode(0x0660 + i),
  );
  static final _digitPattern = RegExp('[0-9]');

  String _toEasternDigits(String input) => input.replaceAllMapped(
    _digitPattern,
    (m) => _easternDigits[int.parse(m[0]!)],
  );
}

/// أيّ تقويمٍ يُعرض.
enum AppDateCalendar {
  /// «١٥ رجب ١٤٤٦».
  hijri,

  /// «15 Sep 2026».
  gregorian,

  /// الاثنان معاً — راجع [AppDateLayout] لتخطيطهما.
  both,
}

/// تخطيط التقويمين حين [AppDateCalendar.both].
enum AppDateLayout {
  /// كلٌّ بسطره — `Column`.
  stacked,

  /// بسطرٍ واحد يلتفّ عند الحاجة، **لا يُقطع أبداً** — `Text.rich`.
  inline,
}

/// صيغة الشهر.
enum AppDateMonthFormat {
  /// `09` — رقمان، بفاصلة [AppDateText.partSeparator].
  numeric,

  /// `Sep` / `رجب` (نفسه الكامل عربياً — لا اختصار متعارَفٌ عليه لأسماء
  /// الأشهر الهجرية).
  nameShort,

  /// `September` / `رجب`.
  nameFull,
}

/// لغة الأسماء والأرقام.
enum AppDateLanguage {
  /// تتبع `context.isAr` — لغة الواجهة الحالية.
  auto,

  arabic,
  english,
}
