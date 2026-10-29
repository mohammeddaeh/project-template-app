import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/svg_inline_styles.dart' show inlineSvgStyles;

/// `flutter_svg` does not apply `<style>` rules: an SVG that colours itself
/// through CSS classes draws black, with no error. Every SVG asset carries its
/// colours as presentation attributes; fix a new one with
/// `dart run scripts/svg_inline_styles.dart <file.svg>`.
void main() {
  final svgs = Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'));

  for (final file in svgs) {
    final name = file.path.replaceAll(r'\', '/');
    test('$name has no <style> or CSS class left to resolve', () {
      final svg = file.readAsStringSync();
      expect(svg, isNot(contains('<style')));
      expect(svg, isNot(contains('class="')));
    });
  }

  test('inlineSvgStyles writes each class rule onto its elements', () {
    const svg =
        '<svg><defs><style>.a{fill:#f7bd31;}.b,.c{stroke-width:2}</style></defs>'
        '<path class="a" d="M0"/><rect class="b c" x="1"/><circle r="3"/></svg>';
    expect(
      inlineSvgStyles(svg),
      '<svg><defs></defs>'
      '<path d="M0" fill="#f7bd31"/><rect x="1" stroke-width="2"/><circle r="3"/></svg>',
    );
  });

  test('an SVG without <style> is returned untouched', () {
    const svg = '<svg><path fill="#000" d="M0"/></svg>';
    expect(inlineSvgStyles(svg), svg);
  });
}
