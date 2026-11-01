import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/widgets/indicators/animated_count.dart';
import 'package:app_template/ui/widgets/layout/app_step_switcher.dart';
import 'package:app_template/ui/widgets/lists/list_appear_tracker.dart';
import 'package:app_template/ui/widgets/wrappers/shake_on_error.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('AppMotion.of', () {
    testWidgets('standard durations normally', (tester) async {
      late MotionValues m;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              m = AppMotion.of(c);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(m.base, AppMotion.base);
      expect(m.isReduced, isFalse);
    });

    testWidgets('zero when the user asked to reduce motion', (tester) async {
      late MotionValues m;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              m = AppMotion.of(c);
              return const SizedBox();
            },
          ),
          reduceMotion: true,
        ),
      );
      expect([m.fast, m.base, m.slow, m.stagger], everyElement(Duration.zero));
      expect(m.isReduced, isTrue);
    });
  });

  group('ListAppearTracker', () {
    test('a row animates once, staggered within its batch, capped', () {
      final t = ListAppearTracker()..observeLength(20);
      expect(
        [for (var i = 0; i < 10; i++) t.staggerFor(i)],
        [
          0, 1, 2, 3, 4, 5, 6, 7, 7, 7, //
        ],
      );
      expect(t.staggerFor(3), isNull, reason: 'scrolled back: drawn still');
    });

    test('the next page staggers from its own first row', () {
      final t = ListAppearTracker()..observeLength(20);
      for (var i = 0; i < 20; i++) {
        t.staggerFor(i);
      }
      t.observeLength(40);
      expect(t.staggerFor(20), 0);
      expect(t.staggerFor(21), 1);
    });

    test('a refresh shows the list as new again', () {
      final t = ListAppearTracker()..observeLength(10);
      t.staggerFor(0);
      t.observeLength(5);
      expect(t.staggerFor(0), 0);
    });
  });

  testWidgets('AnimatedCount settles on the final value', (tester) async {
    await tester.pumpWidget(_host(const AnimatedCount(value: 1234)));
    await tester.pumpAndSettle();
    expect(find.text('1,234'), findsOneWidget);
  });

  testWidgets('ShakeOnError moves on a new error and rests after', (
    tester,
  ) async {
    Widget field(String? error) =>
        _host(ShakeOnError(error: error, child: const Text('field')));
    await tester.pumpWidget(field(null));
    final rest = tester.getTopLeft(find.text('field'));

    await tester.pumpWidget(field('required'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.text('field')), isNot(rest));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('field')), rest);
  });

  testWidgets('ShakeOnError stays still when motion is reduced', (
    tester,
  ) async {
    Widget field(String? error) => _host(
      ShakeOnError(error: error, child: const Text('field')),
      reduceMotion: true,
    );
    await tester.pumpWidget(field(null));
    final rest = tester.getTopLeft(find.text('field'));
    await tester.pumpWidget(field('required'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.text('field')), rest);
  });

  testWidgets('AppStepSwitcher shows the new step after its transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppStepSwitcher(step: 0, child: Text('email'))),
    );
    await tester.pumpWidget(
      _host(const AppStepSwitcher(step: 1, child: Text('code'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('code'), findsOneWidget);
    expect(find.text('email'), findsNothing);
  });
}
