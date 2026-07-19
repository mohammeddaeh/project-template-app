import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// UI helper widget to display an SVG icon from assets.
/// [iconColor] tints the icon; [padding] is optional.
Widget defaultSvgImg({
  double? height,
  double? width,
  required String svg,
  Color? iconColor,
  BoxFit? boxFit,
  EdgeInsetsDirectional? padding,
}) {
  return Padding(
    padding: padding ?? EdgeInsets.zero,
    child: iconColor != null
        ? SvgPicture.asset(
            svg,
            width: width,
            height: height,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            fit: boxFit ?? BoxFit.contain,
          )
        : SvgPicture.asset(
            svg,
            width: width,
            height: height,
            fit: boxFit ?? BoxFit.contain,
          ),
  );
}
