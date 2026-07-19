import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// أنواع الـ labels الدلالية.
enum AppLabelVariant {
  success,
  warning,
  error,
  info,
  neutral,
  primary,
}

/// شارة نصية صغيرة تعبّر عن حالة دلالية (نجاح / تحذير / خطأ / ...).
///
/// **الفرق عن [BadgeWidget]:** `AppLabel` تعرض نصاً مستقلاً في مكانه.
/// `BadgeWidget` يُغطِّي فوق widget أخرى كعدد التنبيهات.
///
/// ```dart
/// AppLabel(labelKey: LocaleKeys.active, variant: AppLabelVariant.success)
/// AppLabel(labelKey: LocaleKeys.pending, variant: AppLabelVariant.warning)
/// AppLabel(labelKey: LocaleKeys.rejected, variant: AppLabelVariant.error)
/// AppLabel(labelKey: LocaleKeys.draft, variant: AppLabelVariant.neutral)
///
/// // مع أيقونة
/// AppLabel(
///   labelKey: LocaleKeys.verified,
///   variant: AppLabelVariant.success,
///   icon: Icons.verified_rounded,
/// )
///
/// // قابل للضغط
/// AppLabel(
///   labelKey: LocaleKeys.viewDetails,
///   variant: AppLabelVariant.primary,
///   onTap: () => context.router.push(const DetailsRoute()),
/// )
///
/// // حجم مضغوط (داخل الجداول)
/// AppLabel(labelKey: LocaleKeys.closed, variant: AppLabelVariant.error, compact: true)
/// ```
class AppLabel extends StatelessWidget {
  const AppLabel({
    super.key,
    this.labelKey,
    this.labelText,
    this.variant = AppLabelVariant.neutral,
    this.icon,
    this.onTap,
    this.compact = false,
  }) : assert(
          labelKey != null || labelText != null,
          'AppLabel: provide labelKey or labelText',
        );

  final String? labelKey;
  final String? labelText;
  final AppLabelVariant variant;

  /// أيقونة اختيارية تسبق النص
  final IconData? icon;

  final VoidCallback? onTap;

  /// يقلل الـ padding للاستخدام داخل الجداول والبطاقات المضغوطة
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    final (bg, fg) = switch (variant) {
      AppLabelVariant.success => (colors.statusSuccessBg, colors.statusSuccessFg),
      AppLabelVariant.warning => (colors.statusWarningBg, colors.statusWarningFg),
      AppLabelVariant.error   => (colors.statusErrorBg,   colors.statusErrorFg),
      AppLabelVariant.info    => (colors.statusInfoBg,    colors.statusInfoFg),
      AppLabelVariant.neutral => (colors.statusNeutralBg, colors.statusNeutralFg),
      AppLabelVariant.primary => (colors.primaryContainer, colors.onPrimaryContainer),
    };

    final label = labelKey != null ? labelKey!.tr() : labelText!;
    final vPad = compact ? 3.0 : 5.0;
    final hPad = compact ? 8.0 : 10.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 11 : 13, color: fg),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: decoration,
          child: content,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: decoration,
      child: content,
    );
  }
}
