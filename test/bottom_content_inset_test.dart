import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/screen_sizes_extensions.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/navigation/app_bottom_bar.dart';
import 'package:app_template/ui/widgets/navigation/nav_item.dart';

/// R15 — a tab's content ends at the bottom bar, never behind it.
///
/// The failure this guards is silent: a bar drawn over the body hides the last
/// item of every list, and the screen still builds, scrolls and throws nothing.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  test('the shell does not extend its body behind the bar', () {
    final src = File(
      'lib/features/home/presentation/pages/main_shell_screen.dart',
    ).readAsStringSync();
    expect(src.contains('extendBody: true'), isFalse);
  });

  final items = [
    for (final key in [
      LocaleKeys.tabHome,
      LocaleKeys.tabSettings,
      LocaleKeys.tabProfile,
      LocaleKeys.showcaseBottomBarExplore,
      LocaleKeys.showcaseBottomBarSaved,
    ])
      NavItem(
        icon: Icons.circle_outlined,
        activeIcon: Icons.circle,
        labelKey: key,
        screenBuilder: () => const SizedBox(),
      ),
  ];

  for (final style in AppBottomBarStyle.values) {
    testWidgets('${style.name}: the body ends where the bar begins', (
      tester,
    ) async {
      late double contentInset;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            padding: EdgeInsets.only(bottom: 24),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: EasyLocalization(
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
                home: Scaffold(
                  body: Builder(
                    key: const Key('body'),
                    builder: (context) {
                      contentInset = context.bottomContentInset;
                      return const SizedBox.expand();
                    },
                  ),
                  bottomNavigationBar: AppBottomBar(
                    key: const Key('bar'),
                    items: items,
                    currentIndex: 0,
                    onTap: (_) {},
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Five tabs on a narrow phone: no style overflows its bar.
      expect(tester.takeException(), isNull);
      final body = tester.getRect(find.byKey(const Key('body')));
      final bar = tester.getRect(find.byKey(const Key('bar')));
      expect(body.bottom, lessThanOrEqualTo(bar.top));
      expect(
        contentInset,
        0,
        reason: 'nothing covers the body inside the shell — no padding owed',
      );
    });
  }

  testWidgets('a screen outside the shell pads for the system bar', (
    tester,
  ) async {
    late double contentInset;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(bottom: 24),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                contentInset = context.bottomContentInset;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    expect(contentInset, 24);
  });
}
