import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// What the screen reports (`context.screen`) and the wrappers that adapt a
/// page to it: insets, system bars, the keyboard and the flavor ribbon.
class ScreenDemo extends StatefulWidget {
  const ScreenDemo({super.key});

  @override
  State<ScreenDemo> createState() => _ScreenDemoState();
}

class _ScreenDemoState extends State<ScreenDemo> {
  bool _top = true;
  bool _bottom = true;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final s = context.screen;
    final colors = context.colors;

    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

    Widget hint(String text) => Padding(
      padding: EdgeInsets.only(bottom: context.screen.space(12)),
      child: Text(
        text,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'context.screen',
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (name, value) in [
                  ('screenClass', s.screenClass.name),
                  ('width × height', '${fmt(s.width)} × ${fmt(s.height)}'),
                  ('isTablet', '${s.isTablet}'),
                  ('isLandscape', '${s.isLandscape}'),
                  ('scale', fmt(s.scale)),
                  ('gutter', fmt(s.gutter)),
                  ('gridColumns', '${s.gridColumns}'),
                  ('space(24)', fmt(s.space(24))),
                  ('size(115)', fmt(s.size(115))),
                  (
                    'pick(compact: 1, medium: 2, expanded: 3, large: 4)',
                    '${s.pick(compact: 1, medium: 2, expanded: 3, large: 4)}',
                  ),
                ])
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.screen.space(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        const ResponsiveGap.horizontal(8),
                        Text(value, style: context.textTheme.headlineSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        DemoPlayground(
          call: 'ResponsiveContentBox',
          knobs: [
            EnumKnob(
              'width',
              ContentWidth.values,
              ContentWidth.content,
              typeName: 'ContentWidth',
            ),
            const BoolKnob(
              'horizontalPadding',
              initial: true,
              apiDefault: true,
            ),
          ],
          trailingCode: const ['child: …'],
          builder: (context, k) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The shaded frame is the available width; the box sits in it.
              ColoredBox(
                color: colors.feedbackWarning.withValues(alpha: 0.3),
                child: ResponsiveContentBox(
                  width: k('width'),
                  horizontalPadding: k('horizontalPadding'),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    color: colors.primaryContainer,
                    child: Text(
                      LocaleKeys.showcaseScreenContent.tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const ResponsiveGap(12),
              hint(LocaleKeys.showcaseScreenBoxHint.tr()),
              _BoxLimits(
                title: LocaleKeys.showcaseScreenThisScreen.tr(),
                metrics: s,
              ),
              const ResponsiveGap(12),
              _SimulatedWidth(
                builder: (metrics) => _BoxLimits(
                  title:
                      'ScreenMetrics.fromSize(Size(${_fmt(metrics.width)}, 900))',
                  metrics: metrics,
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'ResponsiveBuilder(builder: (context, screen) => …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hint(LocaleKeys.showcaseScreenBuilderHint.tr()),
              ResponsiveBuilder(
                builder: (context, screen) {
                  Widget pane(String label) => Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Text(
                      label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  );
                  final list = pane(LocaleKeys.showcaseScreenPaneList.tr());
                  final detail = pane(LocaleKeys.showcaseScreenPaneDetail.tr());
                  // The composition changes, not a number: one column on a
                  // phone, side by side from a tablet up.
                  return screen.isTablet
                      ? Row(
                          children: [
                            Expanded(child: list),
                            const ResponsiveGap.horizontal(8),
                            Expanded(flex: 2, child: detail),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [list, const ResponsiveGap(8), detail],
                        );
                },
              ),
            ],
          ),
        ),
        const _GapPlayground(),
        DemoBlock(
          code: 'SafeAreaWrapper(top:, bottom:, child:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hint(LocaleKeys.showcaseScreenSafeHint.tr()),
              Row(
                children: [
                  for (final (name, value, set) in [
                    ('top', _top, (bool v) => setState(() => _top = v)),
                    (
                      'bottom',
                      _bottom,
                      (bool v) => setState(() => _bottom = v),
                    ),
                  ]) ...[
                    Text(name, style: context.textTheme.bodySmall),
                    Switch.adaptive(value: value, onChanged: set),
                    const ResponsiveGap.horizontal(8),
                  ],
                ],
              ),
              const ResponsiveGap(8),
              _InsetFrame(top: _top, bottom: _bottom),
            ],
          ),
        ),
        DemoBlock(
          code: 'SystemBarStyle(child:) · .lightIcons · .darkIcons',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hint(LocaleKeys.showcaseScreenBarHint.tr()),
              SystemBarStyle(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final theme in Brightness.values)
                        for (final (name, onLight, onDark) in [
                          ('SystemBarStyle', null, null),
                          ('.lightIcons', Brightness.light, Brightness.light),
                          ('.darkIcons', Brightness.dark, Brightness.dark),
                        ])
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.screen.space(2),
                            ),
                            child: Text(
                              '${theme.name} theme · $name → icons: '
                              '${SystemBarStyle.resolve(theme, onLightTheme: onLight, onDarkTheme: onDark).statusBarIconBrightness?.name}',
                              style: context.textTheme.bodySmall,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'KeyboardDismissWidget(child:)',
          child: KeyboardDismissWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hint(LocaleKeys.showcaseScreenKeyboardHint.tr()),
                CustomTextField(
                  labelText: LocaleKeys.showcaseName.tr(),
                  onTapOutsideDismissTheKeyboard: false,
                ),
                const ResponsiveGap(48),
              ],
            ),
          ),
        ),
        DemoBlock(
          code: 'FlavorBanner(child:)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hint(LocaleKeys.showcaseScreenFlavorHint.tr(args: [Env.flavor])),
              ClipRRect(
                borderRadius: AppRadius.mdRadius,
                child: SizedBox(
                  height: context.screen.size(96),
                  child: FlavorBanner(
                    child: ColoredBox(
                      color: colors.bgNeutral,
                      child: Center(
                        child: Text(
                          LocaleKeys.showcaseScreenContent.tr(),
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 16,
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.smRadius),
  );
}

/// A small "device" whose system insets are simulated, so [SafeAreaWrapper]
/// has something to keep its content out of.
class _InsetFrame extends StatelessWidget {
  const _InsetFrame({required this.top, required this.bottom});

  final bool top;
  final bool bottom;

  static const _inset = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget band() => Container(height: _inset, color: colors.bgNeutral);

    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: SizedBox(
        height: context.screen.size(140),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: _inset, bottom: _inset),
          ),
          child: Stack(
            children: [
              Column(children: [band(), const Spacer(), band()]),
              Positioned.fill(
                child: SafeAreaWrapper(
                  top: top,
                  bottom: bottom,
                  child: Container(
                    alignment: Alignment.center,
                    color: colors.primaryContainer.withValues(alpha: 0.8),
                    child: Text(
                      LocaleKeys.showcaseScreenContent.tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmt(double v) => v.isInfinite
    ? '∞'
    : v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(2);

/// What [ResponsiveContentBox] reads from a [ScreenMetrics]: the width
/// limits and the side padding.
class _BoxLimits extends StatelessWidget {
  const _BoxLimits({required this.title, required this.metrics});

  final String title;
  final ScreenMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final muted = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textTheme.labelMedium),
          const ResponsiveGap(4),
          for (final (name, value) in [
            ('screenClass', metrics.screenClass.name),
            ('formMaxWidth  (ContentWidth.form)', _fmt(metrics.formMaxWidth)),
            (
              'contentMaxWidth  (ContentWidth.content)',
              _fmt(metrics.contentMaxWidth),
            ),
            ('gutter  (horizontalPadding)', _fmt(metrics.gutter)),
          ])
            Row(
              children: [
                Expanded(child: Text(name, style: muted)),
                Text(value, style: context.textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

/// A width slider and the metrics a screen of that width would report —
/// computed, not applied, so the real screen stays as it is.
class _SimulatedWidth extends StatefulWidget {
  const _SimulatedWidth({required this.builder});

  final Widget Function(ScreenMetrics metrics) builder;

  @override
  State<_SimulatedWidth> createState() => _SimulatedWidthState();
}

class _SimulatedWidthState extends State<_SimulatedWidth> {
  double _width = 390;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              LocaleKeys.showcaseScreenSimWidth.tr(),
              style: context.textTheme.bodySmall,
            ),
            Expanded(
              child: Slider.adaptive(
                value: _width,
                min: 320,
                max: 1280,
                divisions: 24,
                label: _fmt(_width),
                onChanged: (v) => setState(() => _width = v),
              ),
            ),
          ],
        ),
        widget.builder(ScreenMetrics.fromSize(Size(_width, 900))),
      ],
    );
  }
}

/// [ResponsiveGap] and the two scalers behind it, `space` and `size`, for a
/// base value of one's choosing.
class _GapPlayground extends StatefulWidget {
  const _GapPlayground();

  @override
  State<_GapPlayground> createState() => _GapPlaygroundState();
}

class _GapPlaygroundState extends State<_GapPlayground> {
  double _base = 24;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final s = context.screen;
    final colors = context.colors;
    final b = _base.toStringAsFixed(0);
    final muted = context.textTheme.bodySmall?.copyWith(
      color: colors.textMuted,
    );

    return DemoBlock(
      code: 'ResponsiveGap($b)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.showcaseScreenGapHint.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const ResponsiveGap(12),
          _Bar(color: colors.primaryContainer),
          ColoredBox(
            color: colors.feedbackWarning,
            child: ResponsiveGap(_base),
          ),
          _Bar(color: colors.primaryContainer),
          const ResponsiveGap(12),
          Row(
            children: [
              Text(
                LocaleKeys.showcaseScreenBase.tr(),
                style: context.textTheme.bodySmall,
              ),
              Expanded(
                child: Slider.adaptive(
                  value: _base,
                  max: 96,
                  divisions: 24,
                  label: b,
                  onChanged: (v) => setState(() => _base = v),
                ),
              ),
            ],
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (name, value) in [
                  ('context.screen.scale', _fmt(s.scale)),
                  ('context.screen.space($b)', _fmt(s.space(_base))),
                  ('context.screen.size($b)', _fmt(s.size(_base))),
                ])
                  Row(
                    children: [
                      Expanded(child: Text(name, style: muted)),
                      Text(value, style: context.textTheme.titleMedium),
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
