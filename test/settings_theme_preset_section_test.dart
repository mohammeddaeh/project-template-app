import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/platform/storage/adapters/in_memory_storage_adapter.dart';
import 'package:app_template/features/settings/presentation/cubits/theme_preset_cubit.dart';
import 'package:app_template/features/settings/presentation/widgets/settings_theme_preset_section.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/responsive/responsive_scope.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/theme/app_theme_presets.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('one card per theme; a tap chooses it', (tester) async {
    // With one palette the section draws nothing — the case it exists for
    // needs two.
    if (AppThemePresets.all.length < 2) return;
    final cubit = ThemePresetCubit(InMemoryStorageAdapter());
    addTearDown(cubit.close);

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
            builder: (context, child) => ResponsiveScope(child: child!),
            home: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: const SettingsThemePresetSection(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final second = AppThemePresets.all[1];
    expect(find.text(second.nameKey.tr()), findsOneWidget);
    expect(
      find.bySemanticsLabel(AppThemePresets.all.first.nameKey.tr()),
      findsOneWidget,
    );

    await tester.tap(find.text(second.nameKey.tr()));
    await tester.pumpAndSettle();
    expect(cubit.state, second);
  });
}
