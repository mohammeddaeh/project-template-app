import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:app_template/ui/responsive/responsive_extensions.dart';

/// بطاقةٌ بالشبكة — كم عموداً وكم صفّاً تشغل من [AppBentoGrid].
class BentoTile {
  const BentoTile({required this.child, this.columns = 1, this.rows = 1})
    : assert(columns >= 1 && rows >= 1, 'BentoTile spans at least 1×1');

  final Widget child;

  /// يُقصّ إلى أعمدة الشبكة — بطاقةٌ بأربعة أعمدة على هاتفٍ بعمودين تملأ عرضه.
  final int columns;
  final int rows;
}

/// شبكة «Bento» — بطاقاتٌ بأحجامٍ مختلفة (1×1 · 2×1 · 2×2…) تتراصّ بلا فراغ.
///
/// ```dart
/// AppBentoGrid(
///   tiles: [
///     BentoTile(columns: 2, rows: 2, child: HeroCard()),
///     BentoTile(child: StatCard(value: '12', labelKey: …)),
///     BentoTile(child: StatCard(value: '7', labelKey: …)),
///     BentoTile(columns: 2, child: ActivityCard()),
///   ],
/// )
/// ```
///
/// **الأعمدة من عرض الشبكة نفسها لا الشاشة**: كم خليّةً بعرض [minCellWidth]
/// (مضروباً بـ`context.screen.size`) تسع — عمودان على الهاتف على الأقلّ، وأكثر
/// كلما اتّسعت. فالشبكةُ داخل بطاقةٍ أو عمودٍ ضيّق باللوح لا تُقسَّم بأعمدة
/// الشاشة كلّها، فتصغر خلاياها حتى يفيض ما فيها.
///
/// **تتراصّ بأوّل موضعٍ يسعها** بترتيب [tiles]: بطاقةٌ صغيرة بعد عريضةٍ لم
/// تجد مكاناً بسطرها تملأ الفراغ الذي تركته. والمواضع تتبع اتجاه القراءة.
///
/// الخليّةُ مربّعة افتراضاً ([cellAspectRatio] عرضُها على ارتفاعها)، والشبكة
/// تُبنى كاملةً لا كسولة — للوحةٍ أو رئيسية، لا لقائمةٍ طويلة.
class AppBentoGrid extends StatelessWidget {
  const AppBentoGrid({
    super.key,
    required this.tiles,
    this.spacing = 12,
    this.cellAspectRatio = 1,
  });

  /// أضيقُ خليّةٍ بمقاس التصميم — تتّسع لـ`StatCard` بخطّها الافتراضيّ.
  static const double minCellWidth = 150;

  final List<BentoTile> tiles;
  final double spacing;
  final double cellAspectRatio;

  @override
  Widget build(BuildContext context) {
    final minCell = context.screen.size(minCellWidth);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          2,
          ((constraints.maxWidth + spacing) / (minCell + spacing)).floor(),
        );
        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cellHeight = cellWidth / cellAspectRatio;
        final placed = placeBentoTiles(tiles, columns);
        final rows = placed.fold(0, (m, p) => math.max(m, p.row + p.rows));
        double span(int cells, double cell) =>
            cells * cell + (cells - 1) * spacing;

        return SizedBox(
          height: rows == 0 ? 0 : span(rows, cellHeight),
          child: Stack(
            children: [
              for (final p in placed)
                PositionedDirectional(
                  start: p.column * (cellWidth + spacing),
                  top: p.row * (cellHeight + spacing),
                  width: span(p.columns, cellWidth),
                  height: span(p.rows, cellHeight),
                  child: tiles[p.index].child,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// موضعُ بطاقةٍ بالشبكة — بالخلايا، من بداية سطر القراءة.
@immutable
class BentoPlacement {
  const BentoPlacement(
    this.index,
    this.row,
    this.column,
    this.rows,
    this.columns,
  );

  /// موضعُها بـ[AppBentoGrid.tiles].
  final int index;
  final int row;
  final int column;
  final int rows;
  final int columns;
}

/// يضع كلَّ بطاقةٍ بأوّل موضعٍ يسعها، سطراً بعد سطر — منفصلٌ عن الرسم ليُختبر.
List<BentoPlacement> placeBentoTiles(List<BentoTile> tiles, int columns) {
  final taken = <List<bool>>[];
  bool free(int row, int column, int rows, int width) {
    for (var r = row; r < row + rows; r++) {
      while (taken.length <= r) {
        taken.add(List.filled(columns, false));
      }
      for (var c = column; c < column + width; c++) {
        if (taken[r][c]) return false;
      }
    }
    return true;
  }

  final placed = <BentoPlacement>[];
  for (var i = 0; i < tiles.length; i++) {
    final width = math.min(tiles[i].columns, columns);
    final rows = tiles[i].rows;
    for (var row = 0; ; row++) {
      final column = [
        for (var c = 0; c + width <= columns; c++) c,
      ].where((c) => free(row, c, rows, width)).firstOrNull;
      if (column == null) continue;
      for (var r = row; r < row + rows; r++) {
        taken[r].fillRange(column, column + width, true);
      }
      placed.add(BentoPlacement(i, row, column, rows, width));
      break;
    }
  }
  return placed;
}
