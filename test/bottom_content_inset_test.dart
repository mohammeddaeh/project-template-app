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

  test('the shell extends its body behind the bar only when translucent', () {
    final src = File(
      'lib/features/home/presentation/pages/main_shell_screen.dart',
    ).readAsStringSync();
    expect(RegExp(r'extendBody:\s*([^,]+),').allMatches(src).map((m) => m[1]), [
      'look.translucent',
    ]);
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

  /// The body's rect, the bar's rect, and the inset the body is told to pad.
  Future<(Rect, Rect, double)> pumpShell(
    WidgetTester tester,
    AppBottomBarStyle style, {
    bool translucent = false,
  }) async {
    // The surface itself is narrow — a MediaQuery size alone lays out at 800.
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
                extendBody: translucent,
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
                  translucent: translucent,
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
    return (
      tester.getRect(find.byKey(const Key('body'))),
      tester.getRect(find.byKey(const Key('bar'))),
      contentInset,
    );
  }

  for (final style in AppBottomBarStyle.values) {
    testWidgets('${style.name}: the body ends where the bar begins', (
      tester,
    ) async {
      final (body, bar, contentInset) = await pumpShell(tester, style);

      expect(body.bottom, lessThanOrEqualTo(bar.top));
      expect(
        contentInset,
        0,
        reason: 'nothing covers the body inside the shell — no padding owed',
      );
      if (style == AppBottomBarStyle.expanding) {
        // The selected pill carries its label — equal shares squeezed it to
        // nothing with five tabs on a narrow phone.
        // Measured on the clip around it — the Text keeps its own width.
        final label = tester.getRect(
          find.ancestor(
            of: find.text(LocaleKeys.tabHome.tr()),
            matching: find.byType(AnimatedSize),
          ),
        );
        expect(label.width, greaterThan(24));
      }
    });

    testWidgets('${style.name}: translucent, the bar is owed as padding', (
      tester,
    ) async {
      // R15's one exception: the body runs under the bar, so the bar's height
      // must reach it as the inset a list already pads by.
      final (body, bar, contentInset) = await pumpShell(
        tester,
        style,
        translucent: true,
      );

      expect(body.bottom, greaterThan(bar.top));
      expect(contentInset, greaterThanOrEqualTo(bar.height - 0.5));
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
