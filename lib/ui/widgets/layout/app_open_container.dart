import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// **بطاقةٌ تتمدّد لتصير صفحتها** — انتقال Material «container transform».
///
/// ```dart
/// AppOpenContainer(
///   closedBuilder: (context, open) => OrderCard(order, onTap: open),
///   openBuilder: (context, close) => OrderDetailScreen(id: order.id),
/// )
/// ```
///
/// العين تتبع البطاقة نفسَها وهي تصير الصفحة، فلا يُقرأ الانتقال «شاشةً أخرى
/// جاءت من الجانب» بل «فتحتُ هذا العنصر». يُستعمل من قائمة إلى تفاصيل عنصرها؛
/// لا للتنقّل العام (ذاك لـ`context.router`).
///
/// ⚠️ **الصفحة المفتوحة تُبنى هنا لا بالموجّه**: لا مسار لها، فلا رابط عميق
/// يصلها. شاشةُ تفاصيل يجب أن يصلها رابط تُفتح بـ`context.router.push`.
class AppOpenContainer<T> extends StatelessWidget {
  const AppOpenContainer({
    required this.closedBuilder,
    required this.openBuilder,
    this.onClosed,
    this.radius = AppRadius.md,
    super.key,
  });

  /// العنصر بالقائمة — ونداءُ `open` يفتحه.
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;

  /// الصفحة المفتوحة — ونداءُ `close` يغلقها بقيمةٍ اختيارية.
  final Widget Function(
    BuildContext context,
    void Function({T? returnValue}) close,
  )
  openBuilder;

  /// ما تُغلق به الصفحة (`close(returnValue: …)`).
  final void Function(T? value)? onClosed;

  /// زوايا البطاقة مغلقةً — `AppRadius`.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OpenContainer<T>(
      transitionDuration: AppMotion.of(context).slow,
      transitionType: ContainerTransitionType.fadeThrough,
      closedColor: colors.bgCard,
      openColor: colors.bgPage,
      middleColor: colors.bgCard,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      onClosed: onClosed,
      closedBuilder: closedBuilder,
      openBuilder: (context, close) {
        final page = openBuilder(
          context,
          ({T? returnValue}) => close(returnValue: returnValue),
        );
        // The page is a route the router does not own, so the system back
        // button (and the predictive-back swipe) never reaches it: the
        // router's dispatcher answers instead, and nothing closes.
        if (Router.maybeOf(context) == null) return page;
        return BackButtonListener(
          // `maybePop`, not `close()`: it asks the top route's PopScope first —
          // this page's own, or that of a route pushed above it.
          onBackButtonPressed: () => Navigator.of(context).maybePop(),
          child: page,
        );
      },
    );
  }
}
