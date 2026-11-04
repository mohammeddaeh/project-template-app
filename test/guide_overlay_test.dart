import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/onboarding/guide_overlay.dart';

void main() {
  testWidgets('the bubble opens without an error and closes on its action', (
    tester,
  ) async {
    // Reading MediaQuery in initState threw on every open — the overlay drew
    // the red error box instead of the bubble.
    final target = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: target,
                onPressed: () => GuideOverlay.show(
                  context,
                  targetKey: target,
                  title: 'title',
                  message: 'message',
                  actionLabel: 'got it',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('message'), findsOneWidget);

    await tester.tap(find.text('got it'));
    await tester.pumpAndSettle();
    expect(find.text('message'), findsNothing);
  });
}
