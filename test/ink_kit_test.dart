import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_contracts/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/resources/codegen_loader.g.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/inputs/handwriting_input.dart';
import 'package:app_template/ui/widgets/inputs/signature_pad.dart';

/// Drawing is plain Flutter; reading it is kit_ink, through its contract.
void main() {
  final getIt = GetIt.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  tearDown(getIt.reset);

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
        home: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    ),
  );

  Future<void> scribble(WidgetTester tester) async {
    final pad = tester.getCenter(
      find
          .descendant(
            of: find.byType(SignaturePad),
            matching: find.byType(CustomPaint),
          )
          .last,
    );
    await tester.dragFrom(pad, const Offset(60, 20));
    await tester.pumpAndSettle();
  }

  group('signature', () {
    testWidgets('a drag is a stroke, and the clear button wipes it', (
      tester,
    ) async {
      final ink = InkController();
      await tester.pumpWidget(
        host(SignaturePad(controller: ink, hint: 'Sign')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign'), findsOneWidget);

      await scribble(tester);
      expect(ink.isEmpty, isFalse);
      expect(ink.strokes.single.points.length, greaterThan(1));
      expect(find.text('Sign'), findsNothing);

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();
      expect(ink.isEmpty, isTrue);
    });

    testWidgets('the drawing saves as a PNG, nothing as null', (tester) async {
      final ink = InkController();
      await tester.pumpWidget(host(SignaturePad(controller: ink)));
      await tester.pumpAndSettle();
      expect(await ink.toPng(color: Colors.black), isNull);

      await scribble(tester);
      final png = await tester.runAsync(() => ink.toPng(color: Colors.black));
      expect(png, isNotNull);
      expect(png!.sublist(1, 4), 'PNG'.codeUnits);
    });
  });

  group('handwriting', () {
    testWidgets('without the kit there is nothing to write in', (tester) async {
      await tester.pumpWidget(host(HandwritingInput(onText: (_) {})));
      await tester.pumpAndSettle();
      expect(find.byType(SignaturePad), findsNothing);
    });

    testWidgets('the model is fetched on a tap, then the ink is read', (
      tester,
    ) async {
      final recognizer = FakeInkRecognizer(hasIt: false, candidates: ['hi']);
      getIt.registerSingleton<InkRecognizer>(recognizer);
      String? text;
      await tester.pumpWidget(host(HandwritingInput(onText: (t) => text = t)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Download the handwriting model'), findsOne);

      await tester.tap(find.textContaining('Download the handwriting model'));
      await tester.pumpAndSettle();
      expect(find.text('Turn the writing into text'), findsOneWidget);

      await scribble(tester);
      await tester.tap(find.text('Turn the writing into text'));
      await tester.pumpAndSettle();
      expect(text, 'hi');
      expect(recognizer.lastLanguage, 'en', reason: "the app's language");
      expect(recognizer.lastInk, isNotEmpty);
      expect(
        find.text('Write here with your finger'),
        findsOneWidget,
        reason: 'the pad is cleared for the next word',
      );
    });
  });
}
