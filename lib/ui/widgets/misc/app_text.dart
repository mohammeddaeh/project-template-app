import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/theme_extensions.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.translationKey, {
    super.key,
    this.style,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.inverseColor = false,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  final String translationKey;

  final TextStyle? style;

  final double? fontSize;

  final FontWeight? fontWeight;

  final Color? color;

  final bool inverseColor;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    Color resolvedColor;
    if (color != null) {
      resolvedColor = color!;
    } else if (inverseColor) {
      resolvedColor = scheme.onInverseSurface;
    } else {
      resolvedColor = scheme.onSurface;
    }

    final baseStyle = textTheme.bodyMedium?.copyWith(
      color: resolvedColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );

    return Text(
      translationKey.tr(),
      style: (style ?? baseStyle)?.copyWith(
        color: style?.color ?? resolvedColor,
        fontSize: style?.fontSize ?? fontSize,
        fontWeight: style?.fontWeight ?? fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
