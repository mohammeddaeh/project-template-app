import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/ui/theme/theme_reveal.dart';

void main() {
  const buttonKey = Key('button');
  final overlay = find.descendant(
    of: find.byType(ThemeReveal),
    matching: find.byType(AbsorbPointer),
  );

  Widget app({bool reveal = true, bool reduceMotion = false}) {
    const button = SizedBox(key: buttonKey, width: 40, height: 40);
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: reveal
            ? const ThemeReveal(child: Center(child: button))
            : const Center(child: button),
      ),
    );
  }

  Future<int> tap(WidgetTester tester) async {
    var changes = 0;
    await tester.runAsync(
      () => ThemeReveal.run(tester.element(find.byKey(buttonKey)), () {
        changes++;
      }),
    );
    return changes;
  }

  testWidgets('covers the screen while revealing, then lets go', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(overlay, findsNothing);

    expect(await tap(tester), 1);
    await tester.pump();
    expect(overlay, findsOneWidget);

    // Settled rather than pumped by AppMotion.slow: the ticker was started
    // inside runAsync, so its first tick lands a frame later than the pump.
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
  });

  testWidgets('reduced motion changes the theme with nothing drawn', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduceMotion: true));

    expect(await tap(tester), 1);
    await tester.pump();
    expect(overlay, findsNothing);
  });

  testWidgets('without a ThemeReveal above, the change still happens', (
    tester,
  ) async {
    await tester.pumpWidget(app(reveal: false));

    expect(await tap(tester), 1);
  });
}
