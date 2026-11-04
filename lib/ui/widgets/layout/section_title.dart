import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/responsive/responsive.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.titleKey,
    this.trailing,
    this.padding,
  });

  final String titleKey;
  final Widget? trailing;

  /// افتراضاً ١٢ تحته بمقاس التصميم.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final scheme = context.colorScheme;

    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: context.screen.space(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titleKey.tr(),
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
