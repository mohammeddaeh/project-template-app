import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The fixed [Spacing] gaps, the [AppRadius] scale and the two dividers.
class SpacingDemo extends StatelessWidget {
  const SpacingDemo({super.key});

  static const _vertical = [
    ('vertical4', Spacing.vertical4),
    ('vertical8', Spacing.vertical8),
    ('vertical12', Spacing.vertical12),
    ('vertical16', Spacing.vertical16),
    ('vertical24', Spacing.vertical24),
  ];

  static const _horizontal = [
    ('horizontal4', Spacing.horizontal4),
    ('horizontal8', Spacing.horizontal8),
    ('horizontal16', Spacing.horizontal16),
    ('horizontal24', Spacing.horizontal24),
  ];

  static const _radii = [
    ('sm', AppRadius.smRadius, AppRadius.sm),
    ('md', AppRadius.mdRadius, AppRadius.md),
    ('lg', AppRadius.lgRadius, AppRadius.lg),
    ('pill', AppRadius.pillRadius, AppRadius.pill),
    ('full', AppRadius.fullRadius, AppRadius.full),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget block(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.smRadius,
      ),
    );
    Widget caption(String text) => Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(color: colors.textMuted),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'Spacing.vertical4 … vertical24',
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final (name, gap) in _vertical)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    block(40, 12),
                    ColoredBox(color: colors.feedbackWarning, child: gap),
                    block(40, 12),
                    4.heightBox,
                    caption(name),
                  ],
                ),
            ],
          ),
        ),
        DemoBlock(
          code: 'Spacing.horizontal4 … horizontal24',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, gap) in _horizontal)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      block(24, 24),
                      ColoredBox(
                        color: colors.feedbackWarning,
                        child: SizedBox(height: 24, child: gap),
                      ),
                      block(24, 24),
                      12.widthBox,
                      caption(name),
                    ],
                  ),
                ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppRadius.smRadius … fullRadius',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (name, radius, value) in _radii)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: radius,
                        border: Border.all(color: colors.borderSubtle),
                      ),
                    ),
                    4.heightBox,
                    caption('$name · ${value.toStringAsFixed(0)}'),
                  ],
                ),
            ],
          ),
        ),
        DemoBlock(
          code: 'DividerWidget(thickness:, indent:, endIndent:, vertical:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              caption('DividerWidget()'),
              const DividerWidget(height: 16),
              caption('thickness: 3'),
              const DividerWidget(height: 16, thickness: 3),
              caption('indent: 24, endIndent: 24'),
              const DividerWidget(height: 16, indent: 24, endIndent: 24),
              caption('vertical: true'),
              8.heightBox,
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    block(32, 32),
                    8.widthBox,
                    const DividerWidget(vertical: true),
                    8.widthBox,
                    block(32, 32),
                  ],
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'DashedDivider(color:, dashWidth:, dashSpace:, strokeWidth:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              caption('DashedDivider()'),
              8.heightBox,
              const DashedDivider(),
              16.heightBox,
              caption('dashWidth: 10, dashSpace: 6, strokeWidth: 2'),
              8.heightBox,
              DashedDivider(
                color: colors.primary,
                dashWidth: 10,
                dashSpace: 6,
                height: 2,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
