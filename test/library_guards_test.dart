import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';

import 'package:app_template/ui/widgets/inputs/custom_text_field.dart';
import 'package:app_template/ui/widgets/layout/key_value_row.dart';

/// Library widgets that must not throw on an option combination a screen can
/// legitimately ask for.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget host(Widget child) => EasyLocalization(
    supportedLocales: const [Locale('en')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    assetLoader: const CodegenLoader(),
    child: Builder(
      builder: (context) => MaterialApp(
        theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );

  testWidgets('a password field ignores maxLines instead of asserting', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const CustomTextField(isFieldObscure: true, maxLines: 4)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a field that becomes a password field hides its text', (
    tester,
  ) async {
    await tester.pumpWidget(host(const CustomTextField()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(const CustomTextField(isFieldObscure: true)));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
  });

  testWidgets('copyable shows no copy button without a clipboard service', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const KeyValueRow(labelKey: 'x', value: 'v', copyable: true)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
  });
}
