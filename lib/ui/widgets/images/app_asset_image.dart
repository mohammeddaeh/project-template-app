import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ويدجت موحد لعرض أصول المشروع (SVG أو PNG/JPG/…).
///
/// يكتشف نوع الملف تلقائياً من الامتداد:
///   - `.svg`  → [SvgPicture.asset]
///   - غيره    → [Image.asset]
///
/// الاستخدام:
/// ```dart
/// AppAssetImage(Assets.vectors.logoSvg, height: 80)
/// AppAssetImage(Assets.vectors.logoSvg, height: 80, color: context.colors.logo)
/// AppAssetImage(Assets.images.banner, width: double.infinity, fit: BoxFit.cover)
/// ```
class AppAssetImage extends StatelessWidget {
  const AppAssetImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// لون صبغة اختياري — يعمل مع SVG وraster على حدٍّ سواء.
  final Color? color;
  final BlendMode colorBlendMode;

  bool get _isSvg => path.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color!, colorBlendMode)
            : null,
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }
}
