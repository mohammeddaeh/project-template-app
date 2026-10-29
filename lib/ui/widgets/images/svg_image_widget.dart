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
  }) : _square = false;

  /// **أيقونةٌ مربّعة** بضلع [size]، والرسم داخلها بنسبته (`contain`).
  ///
  /// `SvgPicture(width: 18, height: 18)` لا يرسم مربّعاً: يأخذ الارتفاع ويحفظ
  /// نسبة الرسم، فرسمٌ عريض (`viewBox` 41×23) يخرج بعرض ~32 ويدفع ما بجانبه.
  /// والمربّع هنا صندوقٌ ثابت يملكه الودجة، فلا يتسرّب مقاسُ الرسم إلى الصفّ.
  const SvgImageWidget.icon(
    this.assetPath, {
    super.key,
    required double size,
    this.color,
  }) : width = size,
       height = size,
       fit = BoxFit.contain,
       _square = true;

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final bool _square;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurface;

    final picture = SvgPicture.asset(
      assetPath,
      width: _square ? null : width,
      height: _square ? null : height,
      fit: fit,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
    if (!_square) return picture;
    // قيدٌ محكم: `SvgPicture` يأخذ المربّع كلّه، و`contain` يضع الرسم داخله.
    return SizedBox.square(dimension: width, child: picture);
  }
}
