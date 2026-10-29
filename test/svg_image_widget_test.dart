import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_template/ui/widgets/images/svg_image_widget.dart';

/// The drawn size is measured, not the arguments: `SvgPicture(width:, height:)`
/// keeps the drawing's ratio, so a wide `viewBox` came out wider than asked
/// while a test of the arguments stayed green.
void main() {
  testWidgets('SvgImageWidget.icon draws a square of its size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgImageWidget.icon('assets/images/vectors/logo.svg', size: 18),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SvgImageWidget)), const Size(18, 18));
    expect(tester.getSize(find.byType(SvgPicture)), const Size(18, 18));
  });
}
