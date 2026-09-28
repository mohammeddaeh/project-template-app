import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/dialogs/app_bottom_sheet.dart';

/// A bottom sheet that is the wrong height, or blind to the keyboard, looks
/// exactly like a bottom sheet that was designed that way.
///
/// ## Why this is pinned rather than reviewed
///
/// Both failures render, scroll and dismiss without a single exception:
///
/// - `maxHeightFraction` passed as a *constraint* (with `Column(max)` +
///   `Expanded`) opens every sheet in the app at 90% of the screen, whatever
///   is inside it. A two-line sheet as tall as a full list reads as a design
///   choice, so nobody files it — and the second, worse half is invisible:
///   scroll extent becomes **zero** (content is exactly the sheet), so a field
///   hidden behind the keyboard cannot be dragged into view either.
/// - The keyboard inset read in `show()` instead of `build` is frozen at zero,
///   because the sheet is built before the keyboard animates in. `SafeArea`
///   does not cover for it: `padding.bottom` drops to **zero** while the
///   keyboard is up. That is how the price field at the end of a sheet ended
///   up being typed into blind.
///
/// ## Why the opposite case is half of each pair
///
/// "Short content gives a short sheet" passes just as well for a sheet with no
/// ceiling at all — which is the other way to get this wrong, and it draws the
/// bottom third of a long sheet underneath the keyboard. So every case here is
/// paired with its inverse: sized-to-content **and** capped, padded for the
/// keyboard **and** not padded when there is none.
void main() {
  final theme = AppThemeData.light(const Locale('ar'), AppFonts.byKey('sans'));

  // 400 × 800 logical pixels, so the 0.9 ceiling is a round 720.
  const screenHeight = 800.0;
  const fraction = 0.9;

  Future<void> openSheet(
    WidgetTester tester, {
    required double childHeight,
    double keyboard = 0,
  }) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(400, screenHeight)
      ..viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppBottomSheet.show<void>(
                context,
                title: 'sheet',
                child: SizedBox(height: childHeight, width: 200),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  double sheetHeight(WidgetTester tester) =>
      tester.getSize(find.byType(BottomSheet)).height;

  EdgeInsets contentPadding(WidgetTester tester) =>
      tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      ).padding! as EdgeInsets;

  testWidgets('short content gives a short sheet, not the ceiling', (
    tester,
  ) async {
    await openSheet(tester, childHeight: 80);

    expect(
      sheetHeight(tester),
      lessThan(screenHeight * 0.5),
      reason:
          'The sheet must be the size of its content. At the ceiling instead, '
          'a two-line sheet opens as tall as a full list — and its scroll '
          'extent is zero, so nothing inside it can be dragged into view.',
    );
  });

  testWidgets('tall content stops at the ceiling instead of filling the screen', (
    tester,
  ) async {
    await openSheet(tester, childHeight: 4000);

    // The inverse of the case above: proving "short content, short sheet"
    // alone would also pass with no ceiling at all, which is how a sheet ends
    // up taller than the screen.
    expect(
      sheetHeight(tester),
      lessThanOrEqualTo(screenHeight * fraction + 0.5),
      reason: 'maxHeightFraction is a ceiling; nothing may exceed it.',
    );
    expect(
      sheetHeight(tester),
      greaterThan(screenHeight * 0.7),
      reason: 'Content taller than the ceiling must actually reach it.',
    );
  });

  testWidgets('the keyboard shrinks the ceiling it is measured against', (
    tester,
  ) async {
    const keyboard = 300.0;
    await openSheet(tester, childHeight: 4000, keyboard: keyboard);

    expect(
      sheetHeight(tester),
      lessThanOrEqualTo((screenHeight - keyboard) * fraction + 0.5),
      reason:
          'The ceiling is computed from the screen MINUS the keyboard. Read '
          'from the full screen height, the bottom third of the sheet is '
          'drawn underneath the keyboard.',
    );
  });

  testWidgets('the keyboard inset is added to the content padding', (
    tester,
  ) async {
    const keyboard = 300.0;
    await openSheet(tester, childHeight: 200, keyboard: keyboard);

    expect(
      contentPadding(tester).bottom,
      greaterThanOrEqualTo(keyboard),
      reason:
          'Without this the last field sits behind the keyboard and is typed '
          'into blind — the exact report this was built for.',
    );
  });

  testWidgets('no keyboard means no keyboard padding', (tester) async {
    await openSheet(tester, childHeight: 200);

    // The inverse: padding that always includes an inset-sized gap leaves a
    // dead strip under every sheet that has no keyboard, and would pass the
    // case above by accident.
    expect(
      contentPadding(tester).bottom,
      lessThan(100),
      reason: 'Only the base padding applies when the keyboard is closed.',
    );
  });
}
