import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_colors.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Every token of [AppColors], grouped by role, each swatch under the name to
/// write after `context.colors.`.
class ColorsDemo extends StatelessWidget {
  const ColorsDemo({super.key});

  static List<(String, List<(String, Color)>)> _groups(AppColors c) => [
    (
      LocaleKeys.showcaseColorsScheme,
      [
        ('primary', c.primary),
        ('primaryContainer', c.primaryContainer),
        ('onPrimaryContainer', c.onPrimaryContainer),
        ('secondary', c.secondary),
        ('onSecondary', c.onSecondary),
        ('secondaryContainer', c.secondaryContainer),
        ('onSecondaryContainer', c.onSecondaryContainer),
        ('tertiary', c.tertiary),
        ('onTertiary', c.onTertiary),
        ('tertiaryContainer', c.tertiaryContainer),
        ('onTertiaryContainer', c.onTertiaryContainer),
        ('error', c.error),
        ('onError', c.onError),
        ('errorContainer', c.errorContainer),
        ('onErrorContainer', c.onErrorContainer),
        ('surfaceTint', c.surfaceTint),
      ],
    ),
    (
      LocaleKeys.showcaseColorsSurfaces,
      [
        ('bgPage', c.bgPage),
        ('bgCard', c.bgCard),
        ('bgElevated', c.bgElevated),
        ('bgElevated2', c.bgElevated2),
        ('bgNeutral', c.bgNeutral),
        ('bgInverse', c.bgInverse),
        ('bgDisabled', c.bgDisabled),
      ],
    ),
    (
      LocaleKeys.showcaseColorsText,
      [
        ('textPrimary', c.textPrimary),
        ('textSecondary', c.textSecondary),
        ('textMuted', c.textMuted),
        ('textOnPrimary', c.textOnPrimary),
        ('textOnAccent', c.textOnAccent),
        ('textDisabled', c.textDisabled),
      ],
    ),
    (
      LocaleKeys.showcaseColorsBrand,
      [
        ('bgBrand', c.bgBrand),
        ('onBrand', c.onBrand),
        ('onBrandAccent', c.onBrandAccent),
        ('logo', c.logo),
      ],
    ),
    (
      LocaleKeys.showcaseColorsFeedback,
      [
        ('feedbackSuccess', c.feedbackSuccess),
        ('feedbackError', c.feedbackError),
        ('feedbackWarning', c.feedbackWarning),
        ('feedbackInfo', c.feedbackInfo),
        ('stateError', c.stateError),
        ('primaryToastError', c.primaryToastError),
        ('secondaryToastError', c.secondaryToastError),
      ],
    ),
    (
      LocaleKeys.showcaseColorsStatus,
      [
        ('statusSuccessBg', c.statusSuccessBg),
        ('statusSuccessFg', c.statusSuccessFg),
        ('statusWarningBg', c.statusWarningBg),
        ('statusWarningFg', c.statusWarningFg),
        ('statusErrorBg', c.statusErrorBg),
        ('statusErrorFg', c.statusErrorFg),
        ('statusInfoBg', c.statusInfoBg),
        ('statusInfoFg', c.statusInfoFg),
        ('statusNeutralBg', c.statusNeutralBg),
        ('statusNeutralFg', c.statusNeutralFg),
      ],
    ),
    (
      LocaleKeys.showcaseColorsLines,
      [
        ('outlineVariant', c.outlineVariant),
        ('borderSubtle', c.borderSubtle),
        ('borderFocus', c.borderFocus),
        ('dividerSubtle', c.dividerSubtle),
        ('iconAction', c.iconAction),
        ('iconSubtle', c.iconSubtle),
      ],
    ),
    (
      LocaleKeys.showcaseColorsOther,
      [
        ('avatarBg', c.avatarBg),
        ('avatarFg', c.avatarFg),
        ('shadow', c.shadow),
        ('shadowColor', c.shadowColor),
        ('scrim', c.scrim),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            LocaleKeys.showcaseColorsHint.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        for (final (titleKey, swatches) in _groups(context.colors))
          DemoBlock(
            code: 'context.colors.${swatches.first.$1} …',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titleKey.tr(), style: context.textTheme.headlineSmall),
                12.heightBox,
                // As many 96-wide columns as fit, stretched to fill the row.
                LayoutBuilder(
                  builder: (context, box) {
                    final columns = ((box.maxWidth + 8) / (96 + 8))
                        .floor()
                        .clamp(1, 6);
                    final width = (box.maxWidth - 8 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        for (final (name, color) in swatches)
                          _Swatch(name: name, color: color, width: width),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color, required this.width});

  final String name;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: context.colors.borderSubtle),
          ),
        ),
        4.heightBox,
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
