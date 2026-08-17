import 'package:flutter/material.dart';
import 'package:app_template/shared/widgets/layout/card_loading_scope.dart';
import 'package:app_template/shared/widgets/placeholders/skeleton_widget.dart';

/// بديل لـ [Text] الخام لعرض بيانات ديناميكية (اسم/عنوان/أي نص من الشبكة) —
/// خارج نطاق [CardLoadingScope] يتصرف تماماً مثل [Text] العادي. داخل بطاقة
/// [AppCard.isLoading]: true يرسم نفسه تلقائياً كمستطيل شيمر بدل النص —
/// نفس شجرة الـwidgets، لا حاجة لبناء widget شيمر منفصل ولا لتمرير حالة
/// loading يدوياً بكل عنصر.
///
/// ```dart
/// ShimmerText(branch.name, style: context.textTheme.bodyLarge)
/// // نفس مكان Text(branch.name, style: ...) تماماً
/// ```
class ShimmerText extends StatelessWidget {
  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.shimmerWidth,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// تجاوز صريح لعرض مستطيل الشيمر — افتراضياً (null) يُقاس العرض الفعلي
  /// لـ[text] بنفس [style] عبر `TextPainter`، فيطابق عرض النص الحقيقي تماماً.
  final double? shimmerWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = DefaultTextStyle.of(context).style.merge(style);

    if (!CardLoadingScope.of(context)) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    // Sizes the shimmer box to the SAME width+height Text would actually
    // render at for this exact string/style (real font metrics via
    // TextPainter, not a character-count approximation) — mismatched size
    // here is what causes the card to visibly resize once real data
    // replaces the shimmer.
    final painter = TextPainter(
      text: TextSpan(text: text, style: resolvedStyle),
      textDirection: Directionality.of(context),
      maxLines: maxLines,
    )..layout();

    return SkeletonWidget(
      width: shimmerWidth ?? painter.width,
      height: painter.height,
    );
  }
}
