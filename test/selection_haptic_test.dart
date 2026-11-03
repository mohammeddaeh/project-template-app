import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/core/platform/haptics/haptic_service.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/inputs/app_radio_group.dart';
import 'package:app_template/ui/widgets/inputs/chip_row.dart';
import 'package:app_template/ui/widgets/wrappers/pressable_scale.dart';

class _CountingHaptics implements HapticService {
  int selections = 0;

  @override
  void selection() => selections++;

  @override
  void light() {}

  @override
  void medium() {}

  @override
  void heavy() {}
}

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  late _CountingHaptics haptics;

  setUp(() {
    haptics = _CountingHaptics();
    GetIt.I.registerSingleton<HapticService>(haptics);
  });
  tearDown(() => GetIt.I.unregister<HapticService>());

  testWidgets('a chip tap vibrates once', (tester) async {
    await tester.pumpWidget(
      _host(
        ChipRow<String>(
          items: const ['a', 'b'],
          labelResolver: (s) => s,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('b'));
    expect(haptics.selections, 1);
  });

  testWidgets('the selected radio row again is not a change', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      _host(
        AppRadioGroup<String>(
          options: const {'a': 'A', 'b': 'B'},
          value: 'a',
          onChanged: (_) => changes++,
        ),
      ),
    );

    await tester.tap(find.text('A'));
    expect((changes, haptics.selections), (1, 0));

    await tester.tap(find.text('B'));
    expect((changes, haptics.selections), (2, 1));
  });

  group('PressableScale', () {
    // Scoped: the route transition above has a ScaleTransition of its own.
    final scale = find.descendant(
      of: find.byType(PressableScale),
      matching: find.byType(ScaleTransition),
    );
    double scaleOf(WidgetTester tester) =>
        tester.widget<ScaleTransition>(scale).scale.value;

    testWidgets('shrinks while pressed and springs back on release', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PressableScale(
            child: ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableScale)),
      );
      await tester.pumpAndSettle();
      expect(scaleOf(tester), closeTo(AppMotion.pressedScale, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scaleOf(tester), closeTo(1, 0.001));
    });

    testWidgets('reduced motion draws the child as it is', (tester) async {
      await tester.pumpWidget(
        _host(
          const PressableScale(
            child: ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox(width: 80, height: 40),
            ),
          ),
          reduceMotion: true,
        ),
      );
      expect(scale, findsNothing);
    });
  });
}
