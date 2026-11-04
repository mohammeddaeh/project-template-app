import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/navigation/brand_nav_rail.dart';
import 'package:app_template/ui/widgets/navigation/nav_item.dart';

/// The rail is built only from 840 wide, so nothing on a phone exercises it:
/// an `assert` in NavigationRail or a tab under the status bar would ship
/// unseen. This draws it where it lives — a landscape tablet, right-to-left,
/// with a status bar.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final items = [
    for (final key in [LocaleKeys.tabHome, LocaleKeys.tabSettings])
      NavItem(
        icon: Icons.circle_outlined,
        activeIcon: Icons.circle,
        labelKey: key,
        screenBuilder: () => const SizedBox(),
        badgeCount: key == LocaleKeys.tabSettings ? 3 : null,
      ),
  ];

  testWidgets('draws on a landscape tablet, right of the page, below the '
      'status bar; a tap reports its tab', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);
    final tapped = <int>[];

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        fallbackLocale: const Locale('ar'),
        path: 'assets/translations',
        assetLoader: const CodegenLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppThemeData.light(
              const Locale('ar'),
              AppFonts.available.first,
            ),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: Row(
                children: [
                  BrandNavRail(
                    items: items,
                    currentIndex: 0,
                    onTap: tapped.add,
                  ),
                  const Expanded(child: SizedBox.expand(key: Key('body'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final rail = tester.getRect(find.byType(NavigationRail));
    final body = tester.getRect(find.byKey(const Key('body')));
    expect(rail.left, greaterThanOrEqualTo(body.right - 0.5));

    // The icon, not the label: the label sits low enough to clear 24 even
    // when the rail starts under the status bar.
    final firstIcon = tester.getRect(find.byIcon(Icons.circle));
    expect(firstIcon.top, greaterThanOrEqualTo(24));
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text(LocaleKeys.tabSettings.tr()));
    expect(tapped, [1]);
  });
}
