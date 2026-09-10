import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **«النظام» يجب أن يبقى قابلاً للاختيار.**
///
/// و`context.themeMode` **يحلّ** `system` إلى فاتحٍ أو داكن — فهو يجيب «ما الذي
/// يراه المستخدم» لا «ما الذي اختاره». ومبدِّلٌ يقرؤه يُبرز «فاتح» دائماً على
/// جهازٍ نهاريّ، فلا يجد صاحبُه خياراً يعود به إلى «اتبع النظام» أبداً.
///
/// والقياسُ مصدريّ: بناءُ الشجرة يحتاج `AdaptiveTheme` و`EasyLocalization`
/// و`getIt` مُهيّأً، والمقصودُ **مصدرُ القراءة** لا الرسم.
void main() {
  late String src;

  setUp(() {
    src = File('lib/ui/theme/theme_switcher.dart').readAsStringSync();
  });

  test('it reads the STORED preference, not the resolved brightness', () {
    expect(
      src,
      contains('AdaptiveTheme.of(context).mode'),
      reason: 'the stored choice is what a picker highlights',
    );
    // **والقياسُ على الكود لا على النصّ**: الودجةُ تذكر `context.themeMode`
    // **بتعليقٍ يحذّر منه** — وفحصٌ على الملفّ الخام يفشل على كودٍ صحيح، وهو
    // نفسُ فخّ «اسمٌ يطابق أكثر مما أقصد».
    final code = src
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    expect(
      code.contains('context.themeMode'),
      isFalse,
      reason: 'that resolves `system` away, making it unselectable',
    );
  });

  test('all three modes are offered', () {
    expect(src, contains('AppThemeMode.values'));

    final modes = File('lib/ui/theme/app_theme_mode.dart').readAsStringSync();
    for (final m in const ['light', 'dark', 'system']) {
      expect(modes, contains('AdaptiveThemeMode.$m'));
    }
  });

  test('labels come from translation keys, never hard-coded English', () {
    // `AppThemeMode.label` كانت تردّ `'Light'` و`'Dark'` و`'System'` **وتتجاهل
    // `context`** — نصُّ واجهةٍ مكتوبٌ بالكود (R10)، يظهر إنكليزياً بواجهةٍ عربية.
    final modes = File('lib/ui/theme/app_theme_mode.dart').readAsStringSync();

    expect(src, contains('LocaleKeys.themeSystem'));
    expect(modes.contains("return 'Light'"), isFalse);
    expect(modes.contains("return 'System'"), isFalse);
  });

  test('one switcher exists, not three', () {
    // كان بالقالب ثلاثُ نسخٍ من قرارِ تصميمٍ واحد: `ThemeModeSelector` بلا
    // مستهلك، وكتلةٌ تبني `ListTile` بيدها بشاشة الإعدادات، وهذه. وتُشدَّد
    // إحداها يوماً ولا تُشدَّد الأخريان (R34).
    final modes = File('lib/ui/theme/app_theme_mode.dart').readAsStringSync();
    expect(modes.contains('class ThemeModeSelector'), isFalse);

    final settings = File(
      'lib/features/settings/presentation/pages/settings_screen.dart',
    ).readAsStringSync();
    expect(settings, contains('ThemeSwitcher()'));
    // **والقياسُ على قسم المظهر وحده**: `radio_button_checked` يظهر بمنتقي
    // الخطوط كذلك، وفحصٌ على الملفّ كلِّه يفشل على كودٍ صحيح — نفسُ فخّ «اسمٌ
    // يطابق أكثر مما أقصد».
    final at = settings.indexOf('class _AppearanceSection');
    final next = settings.indexOf('class ', at + 10);
    final section = settings.substring(at, next == -1 ? settings.length : next);
    expect(
      section.contains('Icons.radio_button'),
      isFalse,
      reason: 'the appearance section must not hand-build the picker again',
    );
    expect(section, contains('ThemeSwitcher()'));
  });
}
