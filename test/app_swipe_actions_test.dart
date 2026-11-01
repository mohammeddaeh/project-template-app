import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/lists/app_swipe_actions.dart';
import 'package:app_template/ui/widgets/misc/status_chip.dart';

/// Start and end follow the reading direction, and a confirm that answers
/// `false` leaves the row where it was.
void main() {
  late List<String> rows;
  late List<String> triggered;

  Widget host({
    TextDirection direction = TextDirection.ltr,
    bool withStart = true,
    bool withEnd = true,
    Future<bool> Function()? confirm,
  }) => MaterialApp(
    theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ListView(
            children: [
              for (final r in rows)
                AppSwipeActions(
                  id: r,
                  startAction: withStart
                      ? SwipeAction(
                          icon: Icons.archive_outlined,
                          label: 'archive',
                          tone: StatusTone.info,
                          confirm: confirm,
                          onTriggered: () => setState(() {
                            triggered.add('start:$r');
                            rows.remove(r);
                          }),
                        )
                      : null,
                  endAction: withEnd
                      ? SwipeAction(
                          icon: Icons.delete_outline,
                          label: 'delete',
                          confirm: confirm,
                          onTriggered: () => setState(() {
                            triggered.add('end:$r');
                            rows.remove(r);
                          }),
                        )
                      : null,
                  child: SizedBox(height: 56, child: Center(child: Text(r))),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  setUp(() {
    rows = ['one', 'two'];
    triggered = [];
  });

  testWidgets('LTR: dragging right triggers the start action', (tester) async {
    await tester.pumpWidget(host());
    await tester.drag(find.text('one'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(triggered, ['start:one']);
    expect(find.text('one'), findsNothing);
  });

  testWidgets('RTL: the start action comes from the right side', (
    tester,
  ) async {
    await tester.pumpWidget(host(direction: TextDirection.rtl));
    // Mid-drag the start action's background shows, on the right.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('one')),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(find.text('archive'), findsOneWidget);
    expect(find.text('delete'), findsNothing);
    final rowRight = tester.getTopRight(find.byType(AppSwipeActions).first).dx;
    expect(
      tester.getCenter(find.text('archive')).dx,
      greaterThan(rowRight / 2),
    );
    await gesture.moveBy(const Offset(-400, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(triggered, ['start:one']);
  });

  testWidgets('RTL: dragging right triggers the end action', (tester) async {
    await tester.pumpWidget(host(direction: TextDirection.rtl));
    await tester.drag(find.text('two'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(triggered, ['end:two']);
  });

  testWidgets('confirm answering false keeps the row', (tester) async {
    var asked = 0;
    await tester.pumpWidget(
      host(
        confirm: () async {
          asked++;
          return false;
        },
      ),
    );
    await tester.drag(find.text('one'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(triggered, isEmpty);
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('a side without an action does not move', (tester) async {
    await tester.pumpWidget(host(withStart: false));
    await tester.drag(find.text('one'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(triggered, isEmpty);
    expect(find.text('one'), findsOneWidget);
  });
}
