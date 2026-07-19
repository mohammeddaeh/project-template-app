import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';

/// بطاقة إحصائية مضغوطة للوحات التحكم.
///
/// ```dart
/// StatCard(
///   value: '1,248',
///   labelKey: LocaleKeys.totalOrders,
///   icon: Icons.receipt_long_outlined,
///   color: context.colors.primary,
/// )
///
/// // في شبكة
/// GridView.count(
///   crossAxisCount: 2,
///   mainAxisSpacing: 12,
///   crossAxisSpacing: 12,
///   children: [
///     StatCard(value: stats.total.toString(), labelKey: LocaleKeys.total),
///     StatCard(value: stats.active.toString(), labelKey: LocaleKeys.active,
///         icon: Icons.check_circle_outline, color: context.colors.statusSuccessFg),
///   ],
/// )
///
/// // Loading
/// StatCard(value: '', labelKey: LocaleKeys.revenue, isLoading: true)
/// ```
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    this.labelKey,
    this.labelText,
    this.icon,
    this.color,
    this.onTap,
    this.isLoading = false,
  }) : assert(
          labelKey != null || labelText != null,
          'StatCard: provide labelKey or labelText',
        );

  final String value;
  final String? labelKey;
  final String? labelText;
  final IconData? icon;

  /// لون القيمة والأيقونة — الافتراضي: primary
  final Color? color;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final accent = color ?? colors.primary;
    final labelStr = labelKey != null ? labelKey!.tr() : labelText!;

    return Material(
      color: colors.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colors.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? _buildSkeleton(context)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 20, color: accent),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      value,
                      style: textTheme.headlineMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labelStr,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 24,
          decoration: BoxDecoration(
            color: colors.bgNeutral,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: colors.bgNeutral,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
