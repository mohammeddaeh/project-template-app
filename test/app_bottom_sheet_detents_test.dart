import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/dialogs/app_bottom_sheet.dart';

/// A sheet with detents stops where it is let go: at one of them, or closed.
void main() {
  final theme = AppThemeData.light(const Locale('ar'), AppFonts.byKey('sans'));

  // 400 × 800, so the 0.4 and 0.9 detents are a round 320 and 720.
  const screenHeight = 800.0;

  Future<void> openSheet(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(400, screenHeight);
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
                detents: const [0.4, 0.9],
                // Short content: the sheet still opens at its first detent,
                // and can still be dragged.
                child: const SizedBox(height: 80, width: 200),
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

  Future<void> drag(WidgetTester tester, double dy) async {
    await tester.drag(find.text('sheet'), Offset(0, dy));
    await tester.pumpAndSettle();
  }

  testWidgets('opens at the first detent, whatever the content', (
    tester,
  ) async {
    await openSheet(tester);
    expect(sheetHeight(tester), moreOrLessEquals(screenHeight * 0.4));
  });

  testWidgets('a drag up stops at the next detent, a short drag down returns', (
    tester,
  ) async {
    await openSheet(tester);

    await drag(tester, -300);
    expect(sheetHeight(tester), moreOrLessEquals(screenHeight * 0.9));

    // Released nearer 0.9 than 0.4: it goes back up, not to wherever it was
    // let go.
    await drag(tester, 100);
    expect(sheetHeight(tester), moreOrLessEquals(screenHeight * 0.9));

    await drag(tester, 300);
    expect(sheetHeight(tester), moreOrLessEquals(screenHeight * 0.4));
  });

  testWidgets('a drag below the first detent closes the sheet', (tester) async {
    await openSheet(tester);

    await drag(tester, 300);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
