import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/modules/showcase/presentation/showcase_catalog.dart';
import 'package:app_template/modules/showcase/presentation/showcase_view.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';

/// The tour uses the real widgets, so a widget that changes its API breaks it
/// at compile time — and one that throws while drawing breaks it here.
///
/// The theme page is left out: its switchers need `AdaptiveTheme` and the DI
/// graph, which the settings screen already exercises. Every other page draws
/// with no DI at all — a service the page needs is optional there.
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

  testWidgets('the home view lists every chapter', (tester) async {
    tester.view.physicalSize = const Size(1080, 12000);
    addTearDown(tester.view.reset);
    await pump(tester, const ShowcaseView());
    expect(find.text(LocaleKeys.showcaseTitle.tr()), findsOneWidget);
    for (final g in ShowcaseGroup.values) {
      expect(find.text(g.titleKey.tr()), findsOneWidget);
    }
  });

  for (final page in ShowcaseCatalog.pages) {
    if (page.titleKey == LocaleKeys.showcaseTheme) continue;
    testWidgets('the ${page.titleKey} page draws without errors', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      addTearDown(tester.view.reset);
      await pump(tester, ShowcasePageScreen(page: page));
      expect(tester.takeException(), isNull);
      expect(find.text(page.titleKey.tr()), findsOneWidget);
    });
  }

  test(
    'every public class of the widget library has an example in the tour',
    () {
      // The tour is a mirror: a widget added to the library without an example
      // here leaves it showing less than the template has, and nobody notices.
      final barrel = File('lib/ui/widgets/widgets.dart').readAsStringSync();
      final names = <String>{};
      for (final m in RegExp(
        r"^export '([^']+)'",
        multiLine: true,
      ).allMatches(barrel)) {
        final src = File('lib/ui/widgets/${m[1]}').readAsStringSync();
        for (final c in RegExp(
          r'^(?:abstract |final |sealed |base |interface )*class ([A-Z]\w*)',
          multiLine: true,
        ).allMatches(src)) {
          names.add(c[1]!);
        }
      }
      final tour = Directory('lib/modules/showcase')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.readAsStringSync())
          .join('\n');
      final missing = [
        for (final n in names)
          if (!_exempt.containsKey(n) && !RegExp('\\b$n\\b').hasMatch(tour)) n,
      ]..sort();
      expect(
        missing,
        isEmpty,
        reason:
            'add an example under lib/modules/showcase/presentation/pages/ '
            '(or a reasoned line in _exempt)',
      );
    },
  );
}

/// Library classes the tour does not show, each with its reason.
const _exempt = <String, String>{};
