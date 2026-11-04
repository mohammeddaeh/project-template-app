import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/ui/responsive/responsive_scope.dart';
import 'package:app_template/ui/widgets/layout/app_bento_grid.dart';

const _box = SizedBox.expand();

List<(int, int, int, int)> _layout(List<BentoTile> tiles, int columns) => [
  for (final p in placeBentoTiles(tiles, columns))
    (p.row, p.column, p.rows, p.columns),
];

void main() {
  group('placeBentoTiles', () {
    test('a small tile fills the gap a wide one left behind', () {
      // 1×1 · 2×1 (no room beside the first) · 1×1 (fills that room).
      expect(
        _layout(const [
          BentoTile(child: _box),
          BentoTile(columns: 2, child: _box),
          BentoTile(child: _box),
        ], 2),
        [(0, 0, 1, 1), (1, 0, 1, 2), (0, 1, 1, 1)],
      );
    });

    test('a 2×2 tile holds both rows beside it', () {
      expect(
        _layout(const [
          BentoTile(columns: 2, rows: 2, child: _box),
          BentoTile(child: _box),
          BentoTile(child: _box),
          BentoTile(child: _box),
        ], 4),
        [(0, 0, 2, 2), (0, 2, 1, 1), (0, 3, 1, 1), (1, 2, 1, 1)],
      );
    });

    test('a tile wider than the grid is cut to its width', () {
      expect(_layout(const [BentoTile(columns: 4, child: _box)], 2), [
        (0, 0, 1, 2),
      ]);
    });
  });

  testWidgets('tiles start from the reading side', (tester) async {
    Future<Offset> firstTile(TextDirection direction) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 640)),
          child: Directionality(
            textDirection: direction,
            child: const ResponsiveScope(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 320,
                  child: AppBentoGrid(
                    spacing: 0,
                    tiles: [
                      BentoTile(child: SizedBox.expand(key: Key('first'))),
                      BentoTile(child: _box),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.byKey(const Key('first')));
    }

    // A 320-wide phone: two 160-wide columns.
    expect(await firstTile(TextDirection.ltr), Offset.zero);
    expect(await firstTile(TextDirection.rtl), const Offset(160, 0));
  });
}
