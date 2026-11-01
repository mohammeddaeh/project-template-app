import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/ui/theme/app_theme.dart';
import 'package:app_template/ui/widgets/lists/app_reorderable_list.dart';

/// [AppReorderableList.onReorder] gets the index the item lands on, so
/// `insert(to, removeAt(from))` is right as written — the framework's own
/// callback is one past it when an item moves down.
void main() {
  late List<String> items;
  late List<(int, int)> calls;

  Widget host({bool handle = true}) => MaterialApp(
    theme: AppThemeData.light(const Locale('en'), AppFonts.available.first),
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => AppReorderableList<String>(
          items: items,
          itemKey: (s) => s,
          handle: handle,
          itemBuilder: (context, s, i) => SizedBox(height: 50, child: Text(s)),
          onReorder: (from, to) {
            calls.add((from, to));
            setState(() => items.insert(to, items.removeAt(from)));
          },
        ),
      ),
    ),
  );

  setUp(() {
    items = ['a', 'b', 'c', 'd', 'e'];
    calls = [];
  });

  ReorderCallback frameworkCallback(WidgetTester tester) => tester
      .widget<ReorderableListView>(find.byType(ReorderableListView))
      .onReorder;

  testWidgets('moving down: the framework index is adjusted by one', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    // The framework reports 0 → 3 for "a lands after c".
    frameworkCallback(tester)(0, 3);
    await tester.pump();
    expect(calls, [(0, 2)]);
    expect(items, ['b', 'c', 'a', 'd', 'e']);
  });

  testWidgets('moving up: the index is passed as is', (tester) async {
    await tester.pumpWidget(host());
    frameworkCallback(tester)(4, 1);
    await tester.pump();
    expect(calls, [(4, 1)]);
    expect(items, ['a', 'e', 'b', 'c', 'd']);
  });

  testWidgets('dropped where it was: no callback', (tester) async {
    await tester.pumpWidget(host());
    frameworkCallback(tester)(2, 3);
    frameworkCallback(tester)(2, 2);
    expect(calls, isEmpty);
  });

  testWidgets('dragging the handle moves the row', (tester) async {
    await tester.pumpWidget(host());
    final handle = find.byIcon(Icons.drag_handle_rounded).first;
    await tester.timedDrag(
      handle,
      const Offset(0, 110),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(calls.single.$1, 0);
    expect(items.first, isNot('a'));
    expect(items.indexOf('a'), calls.single.$2);
  });

  testWidgets('without a handle, no handle icon is drawn', (tester) async {
    await tester.pumpWidget(host(handle: false));
    expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
    expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(5));
  });
}
