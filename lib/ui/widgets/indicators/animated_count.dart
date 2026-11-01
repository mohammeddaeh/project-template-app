import 'package:flutter/material.dart';

import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/ui/theme/app_motion.dart';

/// **رقمٌ يعدّ إلى قيمته الجديدة** بدل أن يقفز إليها — عدّاد · رصيد · إحصاء.
///
/// ```dart
/// AnimatedCount(
///   value: state.total,
///   format: AppNumberFormats.count,
///   style: context.textTheme.headlineMedium,
/// )
/// ```
///
/// الحركة تقول «تغيّر الرقم» حتى لمن لم ينظر لحظةَ التغيّر. والشكل من
/// الكتالوج ([AppNumberFormat]) — فلا تنسيقَ أرقامٍ يُكتب هنا. ومع «تقليل
/// الحركة» يظهر الرقم النهائي فوراً.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    required this.value,
    this.format = AppNumberFormats.count,
    this.style,
    this.textAlign,
    super.key,
  });

  final int value;
  final AppNumberFormat format;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: AppMotion.of(context).slow,
      curve: AppMotion.slowCurve,
      builder: (context, v, _) => Text(
        format.apply(v.round(), language: language),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
