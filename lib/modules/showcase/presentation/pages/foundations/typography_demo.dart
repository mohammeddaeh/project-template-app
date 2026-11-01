import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The type scale of `context.textTheme` — each style with its size and
/// weight — then the text widgets: [AppText], [AppLabel] and [GlyphCenter].
class TypographyDemo extends StatelessWidget {
  const TypographyDemo({super.key});

  static List<(String, TextStyle?)> _styles(TextTheme t) => [
    ('displayLarge', t.displayLarge),
    ('displayMedium', t.displayMedium),
    ('displaySmall', t.displaySmall),
    ('headlineLarge', t.headlineLarge),
    ('headlineMedium', t.headlineMedium),
    ('headlineSmall', t.headlineSmall),
    ('titleLarge', t.titleLarge),
    ('titleMedium', t.titleMedium),
    ('titleSmall', t.titleSmall),
    ('bodyLarge', t.bodyLarge),
    ('bodyMedium', t.bodyMedium),
    ('bodySmall', t.bodySmall),
    ('labelLarge', t.labelLarge),
    ('labelMedium', t.labelMedium),
    ('labelSmall', t.labelSmall),
  ];

  static String _weight(FontWeight? w) => w == null ? '—' : 'w${w.value}';

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final sample = LocaleKeys.showcaseTypographySample.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'context.textTheme.…',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (name, style) in _styles(context.textTheme))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '$name · ${style?.fontSize?.toStringAsFixed(0)} · '
                          '${_weight(style?.fontWeight)}',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        sample,
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        DemoBlock(
          code: "AppText('key', fontWeight: …, color: …, inverseColor: …)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText(LocaleKeys.showcaseTypographySample),
              8.heightBox,
              const AppText(
                LocaleKeys.showcaseTypographySample,
                fontWeight: FontWeight.w800,
              ),
              8.heightBox,
              AppText(
                LocaleKeys.showcaseTypographySample,
                color: context.colors.primary,
              ),
              8.heightBox,
              ColoredBox(
                color: context.colors.bgInverse,
                child: Padding(
                  padding: 8.allPadding,
                  child: const AppText(
                    LocaleKeys.showcaseTypographySample,
                    inverseColor: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppLabel(variant: AppLabelVariant.…, icon:, compact:, onTap:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in AppLabelVariant.values)
                    AppLabel(labelText: v.name, variant: v),
                ],
              ),
              12.heightBox,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const AppLabel(
                    labelText: 'icon',
                    variant: AppLabelVariant.success,
                    icon: Icons.check_rounded,
                  ),
                  const AppLabel(
                    labelText: 'compact',
                    variant: AppLabelVariant.info,
                    compact: true,
                  ),
                  AppLabel(
                    labelText: 'onTap',
                    variant: AppLabelVariant.primary,
                    icon: Icons.touch_app_rounded,
                    onTap: () => context.feedback.toast(
                      LocaleKeys.showcaseTypographyTapped.tr(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoBlock(
          code: "GlyphCenter(child: Text('7'))",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.showcaseTypographyGlyphHint.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              12.heightBox,
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Badge(label: 'Text', centered: false),
                  _Badge(label: 'GlyphCenter', centered: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A number in a fixed circle — drawn plain or through [GlyphCenter] so the
/// two sit side by side.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.centered});

  final String label;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '7',
      style: context.textTheme.headlineMedium?.copyWith(
        color: context.colors.onPrimaryContainer,
      ),
    );
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: AppRadius.fullRadius,
          ),
          child: centered ? GlyphCenter(child: text) : text,
        ),
        6.heightBox,
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
