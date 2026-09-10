import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgImageWidget extends StatelessWidget {
  const SvgImageWidget({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurface;

    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
