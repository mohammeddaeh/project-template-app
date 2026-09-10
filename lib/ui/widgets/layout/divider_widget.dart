import 'package:flutter/material.dart';

 class DividerWidget extends StatelessWidget {
  const DividerWidget({
    super.key,
    this.height,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
    this.vertical = false,
  });

  final double? height;
  final double thickness;
  final double indent;
  final double endIndent;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.outlineVariant;

    if (vertical) {
      return VerticalDivider(
        width: thickness,
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        color: color,
      );
    }
    return Divider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}
