import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/modules/showcase/presentation/showcase_section.dart';
import 'package:app_template/modules/showcase/presentation/showcase_view.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';

/// The tour uses the real widgets, so a widget that changes its API breaks it
/// at compile time — and one that throws while drawing breaks it here.
///
/// The theme section is left out: its switchers need `AdaptiveTheme` and the
/// DI graph, which the settings screen already exercises.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        fallbackLocale: const Locale('en'),
        path: 'assets/translations',
        assetLoader: const CodegenLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppThemeData.light(
              const Locale('en'),
              AppFonts.available.first,
            ),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the home view lists every section', (tester) async {
    await pump(tester, const ShowcaseView());
    expect(find.text(LocaleKeys.showcaseTitle.tr()), findsOneWidget);
    for (final s in ShowcaseSection.values) {
      expect(find.text(s.titleKey.tr()), findsOneWidget);
    }
  });

  for (final section in ShowcaseSection.values) {
    if (section == ShowcaseSection.theme) continue;
    testWidgets('the ${section.name} page draws without errors', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      addTearDown(tester.view.reset);
      await pump(tester, ShowcaseSectionPage(section: section));
      expect(tester.takeException(), isNull);
      expect(find.text(section.titleKey.tr()), findsOneWidget);
    });
  }
}
