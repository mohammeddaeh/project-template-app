import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/features/auth/shared/presentation/auth_form_body.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/inputs/custom_text_field.dart';

/// AuthFormBody has no keyboard-dismiss wrapper of its own: the field closes
/// the keyboard on a tap outside it. This holds that for the tap that matters
/// most on a tablet — on the wide margin beside the form.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('a tap on the margin beside the form closes the keyboard', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
            home: const Scaffold(
              body: AuthFormBody(
                padding: EdgeInsets.zero,
                child: CustomTextField(hint: 'email'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    bool focused() => tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode
        .hasFocus;

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focused(), isTrue);

    await tester.tapAt(const Offset(40, 400));
    await tester.pump();
    expect(focused(), isFalse);
  });
}
