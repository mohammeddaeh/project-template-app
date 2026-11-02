import 'package:flutter_test/flutter_test.dart';
import 'package:kit_contracts/kit_contracts.dart';
import 'package:kit_ink/src/mlkit_ink_recognizer.dart';

void main() {
  test('strokes keep their order, points and times', () {
    final ink = toMlkitInk(const [
      InkStroke([InkPoint(1, 2, 100), InkPoint(3, 4, 110)]),
      InkStroke([InkPoint(5, 6, 300)]),
    ]);
    expect(ink.strokes, hasLength(2));
    final first = ink.strokes.first.points;
    expect([first[1].x, first[1].y, first[1].t], [3, 4, 110]);
  });

  test('an empty stroke is dropped — the recogniser rejects it', () {
    final ink = toMlkitInk(const [
      InkStroke([]),
      InkStroke([InkPoint(0, 0, 1)]),
    ]);
    expect(ink.strokes, hasLength(1));
  });
}
