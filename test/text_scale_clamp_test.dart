import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/ui/responsive/responsive.dart';

/// The app-wide text scale clamp has a **ceiling only** — a floor crashes
/// Material's date picker.
///
/// ## What broke, and why nobody sees it
///
/// The clamp used to be `[0.9, 1.3]`. `_DatePickerHeader` derives its own
/// ceiling from the *current* scale (`min(currentScale, 1.05)`) and clamps
/// again on top of ours. On a phone whose system font is shrunk, our floor
/// raises the scale to 0.9, Material then asks for a ceiling of 0.9, and
/// `_ClampedTextScaler` asserts `maxScale > minScale` **strictly**:
///
/// ```text
/// 'package:flutter/src/painting/text_scaler.dart': Failed assertion:
/// line 118 pos 80: 'maxScale > minScale': is not true.
/// ```
///
/// A developer machine runs at scale 1.0, so the picker opens fine there and
/// in every review; it only dies in the hands of someone who made their font
/// smaller. And any floor collides the same way with any widget that derives
/// its ceiling from the current scale — so the rule is the floor's absence,
/// not a different number.
///
/// ## Why the opposite case is half the test
///
/// "The picker opens at 0.5" passes just as well with no clamp at all, which
/// is the failure this scope exists to prevent: a 3.1x system font tears every
/// bar in the app apart. So the ceiling is asserted alongside it.
void main() {
  Future<void> pumpApp(WidgetTester tester, double systemScale) async {
    tester.platformDispatcher.textScaleFactorTestValue = systemScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ResponsiveScope(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDatePicker(
                context: context,
                initialDate: DateTime(2026, 9, 23),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a shrunk system font still opens the date picker', (
    tester,
  ) async {
    await pumpApp(tester, 0.5);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason:
          'A floor on the text scale collides with the ceiling Material '
          'derives from the current scale, and the picker dies on exactly the '
          'devices a developer never tests on.',
    );
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('a huge system font is still capped at the ceiling', (
    tester,
  ) async {
    late TextScaler scaler;
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ResponsiveScope(child: child!),
        home: Builder(
          builder: (context) {
            scaler = MediaQuery.textScalerOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // The inverse of the case above: dropping the clamp altogether would also
    // stop the crash — and hand every bar in the app a 3.1x font.
    expect(
      scaler.scale(14) / 14,
      closeTo(ResponsiveScope.maxTextScale, 0.001),
      reason: 'The ceiling is what this scope exists for; only the floor went.',
    );
  });

  testWidgets('a shrunk system font is passed through, not raised', (
    tester,
  ) async {
    late TextScaler scaler;
    tester.platformDispatcher.textScaleFactorTestValue = 0.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ResponsiveScope(child: child!),
        home: Builder(
          builder: (context) {
            scaler = MediaQuery.textScalerOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      scaler.scale(14) / 14,
      closeTo(0.5, 0.001),
      reason:
          'Someone who shrank their system font chose that. Material has no '
          'floor either, and ours is what broke the picker.',
    );
  });
}
