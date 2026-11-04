import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/responsive/responsive.dart';

class TagWidget extends StatelessWidget {
  const TagWidget({
    super.key,
    required this.labelKey,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String labelKey;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final bg = backgroundColor ?? scheme.surfaceContainerHighest;
    final fg = foregroundColor ?? scheme.onSurface;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.screen.space(8),
        vertical: context.screen.space(4),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labelKey.tr(),
        style: textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
