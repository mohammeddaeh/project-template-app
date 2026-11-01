import 'package:flutter_test/flutter_test.dart';
import 'package:kit_audio/src/audio_level.dart';

void main() {
  test('silence and room noise read as nothing', () {
    expect(levelOfDbfs(-160), 0);
    expect(levelOfDbfs(-50), 0);
    expect(levelOfDbfs(double.nan), 0);
  });

  test('a voice fills the bar in proportion', () {
    expect(levelOfDbfs(-25), closeTo(0.5, 1e-9));
    expect(levelOfDbfs(-10), closeTo(0.8, 1e-9));
  });

  test('full scale and beyond are full', () {
    expect(levelOfDbfs(0), 1);
    expect(levelOfDbfs(3), 1);
  });
}
