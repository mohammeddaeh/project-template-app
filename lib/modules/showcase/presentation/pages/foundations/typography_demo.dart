import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/app_colors.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The type scale of `context.textTheme`, then the text widgets as
/// playgrounds: [Text] with a theme style, [AppText], [AppLabel] and
/// [GlyphCenter].
class TypographyDemo extends StatefulWidget {
  const TypographyDemo({super.key});

  @override
  State<TypographyDemo> createState() => _TypographyDemoState();
}

/// The style names of [TextTheme], in scale order.
const _styleNames = [
  'displayLarge',
  'displayMedium',
  'displaySmall',
  'headlineLarge',
  'headlineMedium',
  'headlineSmall',
  'titleLarge',
  'titleMedium',
  'titleSmall',
  'bodyLarge',
  'bodyMedium',
  'bodySmall',
  'labelLarge',
  'labelMedium',
  'labelSmall',
];

TextStyle? _styleOf(TextTheme t, String? name) => switch (name) {
  'displayLarge' => t.displayLarge,
  'displayMedium' => t.displayMedium,
  'displaySmall' => t.displaySmall,
  'headlineLarge' => t.headlineLarge,
  'headlineMedium' => t.headlineMedium,
  'headlineSmall' => t.headlineSmall,
  'titleLarge' => t.titleLarge,
  'titleMedium' => t.titleMedium,
  'titleSmall' => t.titleSmall,
  'bodyLarge' => t.bodyLarge,
  'bodyMedium' => t.bodyMedium,
  'bodySmall' => t.bodySmall,
  'labelLarge' => t.labelLarge,
  'labelMedium' => t.labelMedium,
  'labelSmall' => t.labelSmall,
  _ => null,
};

/// Colour tokens are chosen by name and resolved at build time, so a theme
/// switch never leaves a stale colour in the controls.
const _colorNames = [
  'primary',
  'secondary',
  'tertiary',
  'textPrimary',
  'textSecondary',
  'textMuted',
  'feedbackSuccess',
  'feedbackError',
  'feedbackWarning',
  'feedbackInfo',
];

Color? _colorOf(AppColors c, String? name) => switch (name) {
  'primary' => c.primary,
  'secondary' => c.secondary,
  'tertiary' => c.tertiary,
  'textPrimary' => c.textPrimary,
  'textSecondary' => c.textSecondary,
  'textMuted' => c.textMuted,
  'feedbackSuccess' => c.feedbackSuccess,
  'feedbackError' => c.feedbackError,
  'feedbackWarning' => c.feedbackWarning,
  'feedbackInfo' => c.feedbackInfo,
  _ => null,
};

const _aligns = <String, TextAlign?>{
  'null': null,
  'TextAlign.start': TextAlign.start,
  'TextAlign.center': TextAlign.center,
  'TextAlign.end': TextAlign.end,
  'TextAlign.justify': TextAlign.justify,
};

const _maxLines = <String, int?>{'null': null, '1': 1, '2': 2, '3': 3};

class _TypographyDemoState extends State<TypographyDemo> {
  int _taps = 0;

  static String _weight(FontWeight? w) => w == null ? '—' : 'w${w.value}';

  static const _icons = <String, IconData?>{
    'null': null,
    'Icons.check_rounded': Icons.check_rounded,
    'Icons.schedule': Icons.schedule,
    'Icons.star_rounded': Icons.star_rounded,
  };

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final sample = LocaleKeys.showcaseTypographySample.tr();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'context.textTheme.…',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final name in _styleNames)
                Padding(
                  padding: EdgeInsets.only(bottom: context.screen.space(12)),
                  child: Builder(
                    builder: (context) {
                      final style = _styleOf(context.textTheme, name);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '$name · '
                              '${style?.fontSize?.toStringAsFixed(0)} · '
                              '${_weight(style?.fontWeight)}',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textMuted,
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
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        DemoPlayground(
          call: 'Text',
          knobs: [
            ChoiceKnob<String>(
              'style',
              {for (final n in _styleNames) 'context.textTheme.$n': n},
              initialCode: 'context.textTheme.bodyLarge',
              required: true,
            ),
            ChoiceKnob<int?>('maxLines', _maxLines, apiDefaultCode: 'null'),
            ChoiceKnob<TextOverflow?>('overflow', {
              'null': null,
              for (final o in TextOverflow.values) 'TextOverflow.${o.name}': o,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<TextAlign?>(
              'textAlign',
              _aligns,
              apiDefaultCode: 'null',
            ),
          ],
          // Dart takes the positional argument after the named ones too.
          trailingCode: const ['LocaleKeys.showcaseTypographyParagraph.tr()'],
          builder: (context, k) => SizedBox(
            width: double.infinity,
            child: Text(
              LocaleKeys.showcaseTypographyParagraph.tr(),
              style: _styleOf(context.textTheme, k('style')),
              maxLines: k('maxLines'),
              overflow: k('overflow'),
              textAlign: k('textAlign'),
            ),
          ),
        ),
        DemoPlayground(
          call: 'AppText',
          knobs: [
            ChoiceKnob<String?>('style', {
              'null': null,
              for (final n in _styleNames) 'context.textTheme.$n': n,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<double?>('fontSize', const {
              'null': null,
              '12': 12,
              '16': 16,
              '20': 20,
              '28': 28,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<FontWeight?>('fontWeight', const {
              'null': null,
              'FontWeight.w300': FontWeight.w300,
              'FontWeight.w500': FontWeight.w500,
              'FontWeight.w700': FontWeight.w700,
              'FontWeight.w800': FontWeight.w800,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<String?>('color', {
              'null': null,
              for (final n in _colorNames) 'context.colors.$n': n,
            }, apiDefaultCode: 'null'),
            const BoolKnob('inverseColor'),
            ChoiceKnob<TextAlign?>(
              'textAlign',
              _aligns,
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<int?>('maxLines', _maxLines, apiDefaultCode: 'null'),
            EnumKnob(
              'overflow',
              TextOverflow.values,
              TextOverflow.ellipsis,
              typeName: 'TextOverflow',
            ),
          ],
          trailingCode: const ['LocaleKeys.showcaseTypographyParagraph'],
          // inverseColor is drawn for an inverse surface — show it on one.
          builder: (context, k) => ColoredBox(
            color: k<bool>('inverseColor')
                ? context.colors.bgInverse
                : Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(context.screen.space(8)),
              child: SizedBox(
                width: double.infinity,
                child: AppText(
                  LocaleKeys.showcaseTypographyParagraph,
                  style: _styleOf(context.textTheme, k('style')),
                  fontSize: k('fontSize'),
                  fontWeight: k('fontWeight'),
                  color: _colorOf(context.colors, k('color')),
                  inverseColor: k('inverseColor'),
                  textAlign: k('textAlign'),
                  maxLines: k('maxLines'),
                  overflow: k('overflow'),
                ),
              ),
            ),
          ),
        ),
        DemoPlayground(
          call: 'AppLabel',
          knobs: [
            TextKnob(
              'labelText',
              initial: LocaleKeys.showcaseTypographyLabel.tr(),
              required: true,
            ),
            EnumKnob(
              'variant',
              AppLabelVariant.values,
              AppLabelVariant.neutral,
              typeName: 'AppLabelVariant',
            ),
            ChoiceKnob<IconData?>('icon', _icons, apiDefaultCode: 'null'),
            const BoolKnob('compact'),
            ChoiceKnob<bool>('onTap', const {
              'null': false,
              '() => setState(() => taps++)': true,
            }, apiDefaultCode: 'null'),
          ],
          builder: (context, k) => Column(
            children: [
              AppLabel(
                labelText: k('labelText'),
                variant: k('variant'),
                icon: k('icon'),
                compact: k('compact'),
                onTap: k<bool>('onTap') ? () => setState(() => _taps++) : null,
              ),
              const ResponsiveGap(8),
              Text(
                LocaleKeys.showcaseTypographyTapCount.tr(args: ['$_taps']),
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppLabelVariant.values',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in AppLabelVariant.values)
                AppLabel(labelText: v.name, variant: v),
            ],
          ),
        ),
        const _GlyphPlayground(),
      ],
    );
  }
}

/// A number in a circle of adjustable size, drawn plain or through
/// [GlyphCenter] — the guide line marks the circle's true centre.
class _GlyphPlayground extends StatefulWidget {
  const _GlyphPlayground();

  @override
  State<_GlyphPlayground> createState() => _GlyphPlaygroundState();
}

class _GlyphPlaygroundState extends State<_GlyphPlayground> {
  bool _centered = true;
  double _size = 56;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    final text = Text(
      '7',
      style: context.textTheme.headlineMedium?.copyWith(
        color: colors.onPrimaryContainer,
        fontSize: _size * 0.55,
      ),
    );
    final caption = context.textTheme.labelSmall?.copyWith(
      color: colors.textMuted,
    );

    return DemoBlock(
      code: _centered ? "GlyphCenter(child: Text('7'))" : "Text('7')",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.showcaseTypographyGlyphHint.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const ResponsiveGap(12),
          Center(
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: AppRadius.fullRadius,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 1,
                    color: colors.feedbackError.withValues(alpha: 0.5),
                  ),
                  if (_centered) GlyphCenter(child: text) else text,
                ],
              ),
            ),
          ),
          const ResponsiveGap(12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('GlyphCenter', style: caption)),
                    Switch.adaptive(
                      value: _centered,
                      onChanged: (v) => setState(() => _centered = v),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('size', style: caption),
                    Expanded(
                      child: Slider.adaptive(
                        value: _size,
                        min: 32,
                        max: 120,
                        divisions: 22,
                        onChanged: (v) => setState(() => _size = v),
                      ),
                    ),
                    SizedBox(
                      width: context.screen.size(40),
                      child: Text(_size.toStringAsFixed(0), style: caption),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
