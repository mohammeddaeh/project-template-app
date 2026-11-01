import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_colors.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The fixed [Spacing] gaps and the [AppRadius] scale, each picked from
/// chips, then the two dividers as playgrounds.
class SpacingDemo extends StatelessWidget {
  const SpacingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    Widget block(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.smRadius,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SpacingPicker(),
        const _RadiusPicker(),
        DemoPlayground(
          call: 'DividerWidget',
          knobs: [
            ChoiceKnob<double?>('height', const {
              'null': null,
              '8': 8,
              '16': 16,
              '32': 32,
            }, apiDefaultCode: 'null'),
            const NumberKnob(
              'thickness',
              initial: 1,
              min: 1,
              max: 8,
              integer: true,
              apiDefault: 1,
            ),
            const NumberKnob(
              'indent',
              initial: 0,
              min: 0,
              max: 64,
              divisions: 8,
              integer: true,
              apiDefault: 0,
            ),
            const NumberKnob(
              'endIndent',
              initial: 0,
              min: 0,
              max: 64,
              divisions: 8,
              integer: true,
              apiDefault: 0,
            ),
            const BoolKnob('vertical'),
          ],
          builder: (context, k) {
            final divider = DividerWidget(
              height: k('height'),
              thickness: k('thickness'),
              indent: k('indent'),
              endIndent: k('endIndent'),
              vertical: k('vertical'),
            );
            if (k<bool>('vertical')) {
              return SizedBox(
                height: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    block(48, 96),
                    12.widthBox,
                    divider,
                    12.widthBox,
                    block(48, 96),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                block(double.infinity, 24),
                divider,
                block(double.infinity, 24),
              ],
            );
          },
        ),
        DemoPlayground(
          call: 'DashedDivider',
          knobs: [
            ChoiceKnob<String?>('color', {
              'null': null,
              for (final n in _colorNames) 'context.colors.$n': n,
            }, apiDefaultCode: 'null'),
            const NumberKnob(
              'dashWidth',
              initial: 5,
              min: 1,
              max: 24,
              integer: true,
              apiDefault: 5,
            ),
            const NumberKnob(
              'dashSpace',
              initial: 3,
              min: 1,
              max: 24,
              integer: true,
              apiDefault: 3,
            ),
            const NumberKnob(
              'height',
              initial: 1,
              min: 1,
              max: 12,
              integer: true,
              apiDefault: 1,
            ),
            const NumberKnob(
              'strokeWidth',
              initial: 1,
              min: 1,
              max: 6,
              integer: true,
              apiDefault: 1,
            ),
          ],
          builder: (context, k) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: DashedDivider(
              color: _colorOf(context.colors, k('color')),
              dashWidth: k('dashWidth'),
              dashSpace: k('dashSpace'),
              height: k('height'),
              strokeWidth: k('strokeWidth'),
            ),
          ),
        ),
      ],
    );
  }
}

const _colorNames = [
  'borderSubtle',
  'primary',
  'secondary',
  'textMuted',
  'feedbackError',
  'feedbackSuccess',
];

Color? _colorOf(AppColors c, String? name) => switch (name) {
  'borderSubtle' => c.borderSubtle,
  'primary' => c.primary,
  'secondary' => c.secondary,
  'textMuted' => c.textMuted,
  'feedbackError' => c.feedbackError,
  'feedbackSuccess' => c.feedbackSuccess,
  _ => null,
};

/// A caption written as code — left to right in either language.
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      text,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colors.textMuted,
      ),
    ),
  );
}

/// Every [Spacing] constant, one picked at a time, between two blocks.
class _SpacingPicker extends StatefulWidget {
  const _SpacingPicker();

  @override
  State<_SpacingPicker> createState() => _SpacingPickerState();
}

class _SpacingPickerState extends State<_SpacingPicker> {
  static const _gaps = {
    'vertical4': Spacing.vertical4,
    'vertical8': Spacing.vertical8,
    'vertical12': Spacing.vertical12,
    'vertical16': Spacing.vertical16,
    'vertical24': Spacing.vertical24,
    'horizontal4': Spacing.horizontal4,
    'horizontal8': Spacing.horizontal8,
    'horizontal16': Spacing.horizontal16,
    'horizontal24': Spacing.horizontal24,
  };

  String _name = 'vertical12';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gap = _gaps[_name]!;
    final vertical = _name.startsWith('vertical');
    Widget block() => Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.smRadius,
      ),
    );
    final marked = ColoredBox(
      color: colors.feedbackWarning,
      child: vertical
          ? SizedBox(width: 48, child: gap)
          : SizedBox(height: 32, child: gap),
    );

    return DemoBlock(
      code: 'Spacing.$_name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 96,
            child: Center(
              child: vertical
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [block(), marked, block()],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [block(), marked, block()],
                    ),
            ),
          ),
          8.heightBox,
          _Caption(
            '${(vertical ? gap.height : gap.width)?.toStringAsFixed(0)} px',
          ),
          8.heightBox,
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChipRow<String>(
              items: _gaps.keys.toList(),
              labelResolver: (n) => n,
              selectedValue: _name,
              onSelected: (n) {
                if (n != null) setState(() => _name = n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The [AppRadius] scale on one sample card.
class _RadiusPicker extends StatefulWidget {
  const _RadiusPicker();

  @override
  State<_RadiusPicker> createState() => _RadiusPickerState();
}

class _RadiusPickerState extends State<_RadiusPicker> {
  static const _radii = {
    'sm': (AppRadius.smRadius, AppRadius.sm),
    'md': (AppRadius.mdRadius, AppRadius.md),
    'lg': (AppRadius.lgRadius, AppRadius.lg),
    'pill': (AppRadius.pillRadius, AppRadius.pill),
    'full': (AppRadius.fullRadius, AppRadius.full),
  };

  String _name = 'md';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (radius, value) = _radii[_name]!;

    return DemoBlock(
      code: 'BoxDecoration(borderRadius: AppRadius.${_name}Radius)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedContainer(
              duration: AppMotion.of(context).base,
              curve: AppMotion.baseCurve,
              width: 200,
              height: 96,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: radius,
                border: Border.all(color: colors.borderSubtle),
              ),
            ),
          ),
          8.heightBox,
          Center(
            child: _Caption('AppRadius.$_name = ${value.toStringAsFixed(0)}'),
          ),
          8.heightBox,
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChipRow<String>(
              items: _radii.keys.toList(),
              labelResolver: (n) => n,
              selectedValue: _name,
              onSelected: (n) {
                if (n != null) setState(() => _name = n);
              },
            ),
          ),
        ],
      ),
    );
  }
}
