import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/infra/config/env.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
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
      padding: const EdgeInsets.only(bottom: 12),
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                        8.widthBox,
                        Text(value, style: context.textTheme.headlineSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        DemoBlock(
          code: 'ResponsiveGap(24)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hint(LocaleKeys.showcaseScreenGapHint.tr()),
              _Bar(color: colors.primaryContainer),
              ColoredBox(
                color: colors.feedbackWarning,
                child: const ResponsiveGap(24),
              ),
              _Bar(color: colors.primaryContainer),
            ],
          ),
        ),
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
                    8.widthBox,
                  ],
                ],
              ),
              8.heightBox,
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
                            padding: const EdgeInsets.symmetric(vertical: 2),
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
                48.heightBox,
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
                  height: 96,
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
        height: 140,
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
