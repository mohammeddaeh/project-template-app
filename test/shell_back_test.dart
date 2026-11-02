import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/features/home/presentation/cubits/navigation_cubit.dart';
import 'package:app_template/features/home/presentation/pages/main_shell_screen.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/navigation/nav_item.dart';

/// System back on the shell: a tab returns to the first, the first asks, and
/// a yes leaves the app.
///
/// The exit was never wired — the dialog closed and the app stayed, which no
/// analyzer or layout test sees: the shell blocks the pop to ask first, so
/// after a yes nothing leaves unless the app says so.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late int exits;
  setUp(() {
    exits = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.pop') exits++;
          return null;
        });
  });

  final items = [
    for (final key in [LocaleKeys.tabHome, LocaleKeys.tabSettings])
      NavItem(
        icon: Icons.circle_outlined,
        activeIcon: Icons.circle,
        labelKey: key,
        screenBuilder: () => Text('screen:$key'),
      ),
  ];

  Future<NavigationCubit> pumpShell(WidgetTester tester) async {
    final cubit = NavigationCubit();
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
            home: BlocProvider.value(
              value: cubit,
              child: MainShellScreen(items: items),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('back on another tab returns to the first, asking nothing', (
    tester,
  ) async {
    final cubit = await pumpShell(tester);
    cubit.onItemTapped(1);
    await tester.pumpAndSettle();

    await systemBack(tester);
    expect(cubit.state.currentIndex, 0);
    expect(find.text(LocaleKeys.exitAppMessage.tr()), findsNothing);
    expect(exits, 0);
  });

  testWidgets('back on the first tab asks, and a yes leaves the app', (
    tester,
  ) async {
    await pumpShell(tester);
    await systemBack(tester);
    expect(find.text(LocaleKeys.exitAppMessage.tr()), findsOneWidget);

    await tester.tap(find.text(LocaleKeys.confirm.tr()));
    await tester.pumpAndSettle();
    expect(exits, 1);
  });

  testWidgets('a no stays, and the next back asks again', (tester) async {
    await pumpShell(tester);
    await systemBack(tester);
    await tester.tap(find.text(LocaleKeys.cancel.tr()));
    await tester.pumpAndSettle();
    expect(exits, 0);

    await systemBack(tester);
    expect(find.text(LocaleKeys.exitAppMessage.tr()), findsOneWidget);
  });
}
