import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/sync_fonts.dart' show fontFileWeight;

/// Every font registered in `pubspec.yaml` declares the weight **written inside
/// its file** (`OS/2 usWeightClass`).
///
/// Flutter picks a face by that inner weight, not by the pubspec line, and
/// synthesises bold when the request is 200 or more above it. A file whose
/// inner weight is 400 registered as 600 draws every w600 as a fake-bold
/// Regular and every w400 with the wrong face — and nothing fails.
/// `scripts/sync_fonts.dart` writes the file's weight; this keeps a hand edit
/// from undoing it.
void main() {
  test('pubspec font weights match the weight inside each file', () {
    final lines = File('pubspec.yaml').readAsLinesSync();
    final asset = RegExp(r'^\s*-\s*asset:\s*(\S+\.(?:ttf|otf))\s*$');
    final weight = RegExp(r'^\s*weight:\s*(\d+)\s*$');

    final mismatches = <String>[];
    var checked = 0;
    for (var i = 0; i < lines.length; i++) {
      final a = asset.firstMatch(lines[i]);
      if (a == null) continue;
      final declared = i + 1 < lines.length
          ? int.tryParse(weight.firstMatch(lines[i + 1])?.group(1) ?? '')
          : null;
      final file = File(a.group(1)!);
      expect(
        file.existsSync(),
        isTrue,
        reason: '${a.group(1)} is registered but missing',
      );
      final inner = fontFileWeight(file);
      if (inner == null) continue;
      checked++;
      if ((declared ?? 400) != inner) {
        mismatches.add(
          '${a.group(1)}: pubspec ${declared ?? 400}, file $inner',
        );
      }
    }

    expect(
      checked,
      greaterThan(0),
      reason: 'no font with an OS/2 table was found',
    );
    expect(mismatches, isEmpty, reason: 'run dart run scripts/sync_fonts.dart');
  });
}
