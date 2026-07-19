import 'package:flutter/material.dart';
import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// يعرض شارة البيئة (Dev / Test) في prod لا شيء يظهر
class FlavorBanner extends StatelessWidget {
  final Widget child;

  const FlavorBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Env.isProd) return child;
    return Material(
      child: Stack(
        children: [child, _buildBanner(context)],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CustomPaint(
        painter: BannerPainter(
          message: Env.label,
          textDirection: Directionality.of(context),
          layoutDirection: Directionality.of(context),
          location: BannerLocation.topStart,
          color: context.colors.secondary,
        ),
      ),
    );
  }
}
