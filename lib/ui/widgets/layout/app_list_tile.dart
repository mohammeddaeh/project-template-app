import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:app_template/ui/widgets/misc/shimmer_text.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// بديل موحَّد لـ [ListTile] يستخدم قيم الثيم الصحيحة.
///
/// ```dart
/// AppListTile(
///   titleKey: LocaleKeys.profile,
///   leadingIcon: Icons.person_outline_rounded,
///   onTap: () => context.router.push(const ProfileRoute()),
/// )
///
/// AppListTile(
///   titleKey: LocaleKeys.logout,
///   titleColor: context.colors.error,
///   leadingIcon: Icons.logout_rounded,
///   showDivider: true,
///   onTap: () => context.read<AuthCubit>().logout(),
/// )
/// ```
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.titleKey,
    this.titleText,
    this.subtitleKey,
    this.subtitleText,
    this.leadingIcon,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.showDivider = false,
    this.padding,
    this.dense = false,
    this.enabled = true,
    this.titleColor,
  }) : assert(
          titleKey != null || titleText != null,
          'AppListTile: provide titleKey or titleText',
        );

  final String? titleKey;
  final String? titleText;
  final String? subtitleKey;
  final String? subtitleText;

  /// أيقونة تسبق العنوان (تُهمَل إن مُرِّر [leading])
  final IconData? leadingIcon;

  /// widget مخصصة تستبدل [leadingIcon]
  final Widget? leading;

  /// widget في الطرف المقابل للعنوان
  final Widget? trailing;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// فاصل أسفل الـ tile
  final bool showDivider;

  final EdgeInsets? padding;

  /// يقلل المساحة الرأسية
  final bool dense;

  final bool enabled;

  /// لون العنوان — الافتراضي: onSurface
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    final titleStr = titleKey != null ? titleKey!.tr() : titleText!;
    final subtitleStr =
        subtitleKey != null ? subtitleKey!.tr() : subtitleText;

    Widget? resolvedLeading;
    if (leading != null) {
      resolvedLeading = leading;
    } else if (leadingIcon != null) {
      resolvedLeading = Icon(
        leadingIcon,
        size: dense ? 18 : 20,
        color: enabled ? colors.iconAction : colors.iconSubtle,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: Padding(
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: dense ? 8 : 12,
                ),
            child: Row(
              children: [
                if (resolvedLeading != null) ...[
                  resolvedLeading,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // **[titleKey] لافتةٌ ثابتة و[titleText] بيانة** — وهو
                      // فرقٌ تعرفه هذه الودجة بواجهتها أصلاً. فداخل
                      // [Skeletonized] يُعرض المفتاحُ المترجَم كما هو ويُلبَس
                      // النصُّ الآتي من الخادم عظماً؛ وخارجها الاثنان [Text].
                      _TileText(
                        text: titleStr,
                        isDynamic: titleKey == null,
                        style: (dense
                                ? textTheme.bodyMedium
                                : textTheme.bodyLarge)
                            ?.copyWith(
                          color: enabled
                              ? (titleColor ?? scheme.onSurface)
                              : colors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitleStr != null) ...[
                        const SizedBox(height: 2),
                        _TileText(
                          text: subtitleStr,
                          isDynamic: subtitleKey == null,
                          style: textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: colors.iconSubtle),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 0.5, color: colors.dividerSubtle),
      ],
    );
  }
}

/// سطرُ العنوان أو الوصف — [ShimmerText] للبيانة و[Text] للّافتة.
///
/// **ولا تُلبَس اللافتةُ عظماً**: «المحافظة» معروفةٌ قبل الطلب وبعده، وسترُها
/// يُخفي ما نعرفه ويجعل شاشةَ الانتظار تُقرأ شاشةً ثالثة لا الشاشةَ نفسَها قبل
/// أن تصل بياناتُها.
class _TileText extends StatelessWidget {
  const _TileText({
    required this.text,
    required this.isDynamic,
    required this.style,
  });

  final String text;
  final bool isDynamic;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) =>
      isDynamic ? ShimmerText(text, style: style) : Text(text, style: style);
}
