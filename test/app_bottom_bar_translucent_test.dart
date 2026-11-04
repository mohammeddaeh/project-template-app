import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_colors.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Every style draws its surface in [AppColors.bgTranslucent] when asked, and
/// only then — a style that keeps its opaque fill hides the body it was told
/// to show.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final theme = AppThemeData.light(
    const Locale('en'),
    AppFonts.available.first,
  );
  final translucent = theme.extension<AppColors>()!.bgTranslucent;

  final items = [
    for (final key in [LocaleKeys.tabHome, LocaleKeys.tabSettings])
      NavItem(
        icon: Icons.circle_outlined,
        activeIcon: Icons.circle,
        labelKey: key,
        screenBuilder: () => const SizedBox(),
      ),
  ];

  Future<List<Color?>> barFills(
    WidgetTester tester,
    AppBottomBarStyle style, {
    required bool see,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        fallbackLocale: const Locale('en'),
        path: 'assets/translations',
        assetLoader: const CodegenLoader(),
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            extendBody: see,
            body: const SizedBox.expand(),
            bottomNavigationBar: AppBottomBar(
              items: items,
              currentIndex: 0,
              onTap: (_) {},
              style: style,
              translucent: see,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byType(AppBottomBar);
    return [
      for (final n in tester.widgetList<NavigationBar>(
        find.descendant(of: bar, matching: find.byType(NavigationBar)),
      ))
        n.backgroundColor,
      for (final d in tester.widgetList<DecoratedBox>(
        find.descendant(of: bar, matching: find.byType(DecoratedBox)),
      ))
        if (d.decoration case BoxDecoration(:final color)) color,
    ];
  }

  for (final style in AppBottomBarStyle.values) {
    testWidgets('${style.name}: translucent only when asked', (tester) async {
      expect(await barFills(tester, style, see: true), contains(translucent));
      expect(
        await barFills(tester, style, see: false),
        isNot(contains(translucent)),
      );
    });
  }
}
