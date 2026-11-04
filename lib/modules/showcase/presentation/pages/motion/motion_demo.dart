import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/app_motion.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The motion the template ships, each with its options as controls — and
/// the durations behind it, which all become zero when the system asks to
/// reduce motion.
class MotionDemo extends StatefulWidget {
  const MotionDemo({super.key});

  @override
  State<MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<MotionDemo> {
  int _count = 1200;
  int _countStep = 250;
  int _step = 0;
  int _steps = 3;
  int _listRun = 0;
  int _items = 4;
  int _presses = 0;
  int _attempt = 0;
  String? _error;
  bool _reduce = false;

  static const _formats = <String, AppNumberFormat>{
    'AppNumberFormats.count': AppNumberFormats.count,
    'AppNumberFormat(grouping: false)': AppNumberFormat(grouping: false),
    'AppNumberFormat(digits: ArabicDigits.indic)': AppNumberFormat(
      digits: ArabicDigits.indic,
    ),
  };

  static const _scales = <String, double>{
    'AppMotion.pressedScale': AppMotion.pressedScale,
    '0.9': 0.9,
    '0.8': 0.8,
    '1.05': 1.05,
  };

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoPlayground(
          call: 'ListItemEntrance',
          knobs: [
            EnumKnob(
              'animation',
              ListItemAppear.values,
              ListItemAppear.fadeSlide,
              typeName: 'ListItemAppear',
            ),
            const BoolKnob('enabled', initial: true, apiDefault: true),
            ChoiceKnob<Duration>('duration', const {
              'Duration(milliseconds: 300)': Duration(milliseconds: 300),
              'AppMotion.fast': AppMotion.fast,
              'AppMotion.slow': AppMotion.slow,
            }, apiDefaultCode: 'Duration(milliseconds: 300)'),
            ChoiceKnob<Duration>('stagger', const {
              'Duration(milliseconds: 35)': Duration(milliseconds: 35),
              'AppMotion.stagger': AppMotion.stagger,
              'Duration(milliseconds: 120)': Duration(milliseconds: 120),
            }, apiDefaultCode: 'Duration(milliseconds: 35)'),
          ],
          trailingCode: const ['staggerIndex: i', 'child: …'],
          builder: (context, k) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A new key per run — or per changed option — plays it again.
              Column(
                key: ValueKey(
                  '$_listRun-$_items-${k<ListItemAppear>('animation')}-'
                  '${k<bool>('enabled')}-${k<Duration>('duration')}-'
                  '${k<Duration>('stagger')}',
                ),
                children: [
                  for (var i = 0; i < _items; i++)
                    ListItemEntrance(
                      staggerIndex: i,
                      animation: k('animation'),
                      enabled: k('enabled'),
                      duration: k('duration'),
                      stagger: k('stagger'),
                      child: AppListTile(
                        titleText: LocaleKeys.showcaseItem.tr(
                          args: ['${i + 1}'],
                        ),
                        leadingIcon: Icons.circle_outlined,
                        dense: true,
                      ),
                    ),
                ],
              ),
              _CountRow(
                label: LocaleKeys.showcaseMotionItems.tr(),
                values: const [2, 4, 8],
                value: _items,
                onChanged: (v) => setState(() => _items = v),
              ),
              AppButton(
                text: LocaleKeys.showcaseReplay.tr(),
                variant: AppButtonVariant.text,
                leadingIcon: Icons.replay,
                onTap: () => setState(() => _listRun++),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppOpenContainer',
          child: AppOpenContainer<void>(
            closedBuilder: (context, open) => AppListTile(
              titleKey: LocaleKeys.showcaseOpenCard,
              leadingIcon: Icons.open_in_full,
              onTap: open,
            ),
            openBuilder: (context, close) => Scaffold(
              appBar: AppBar(title: Text(LocaleKeys.showcaseMotion.tr())),
              body: Center(
                child: AppButton(
                  text: LocaleKeys.showcaseBack.tr(),
                  onTap: close,
                ),
              ),
            ),
          ),
        ),
        DemoBlock(
          code: 'AppStepSwitcher(step: $_step, child: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppStepSwitcher(
                step: _step,
                child: _StepCard(step: _step, of: _steps),
              ),
              12.heightBox,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.showcaseBack.tr(),
                      variant: AppButtonVariant.outlined,
                      isEnabled: _step > 0,
                      onTap: () => setState(() => _step--),
                    ),
                  ),
                  8.widthBox,
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.showcaseNext.tr(),
                      isEnabled: _step < _steps - 1,
                      onTap: () => setState(() => _step++),
                    ),
                  ),
                ],
              ),
              8.heightBox,
              _CountRow(
                label: LocaleKeys.showcaseMotionSteps.tr(),
                values: const [2, 3, 5],
                value: _steps,
                onChanged: (v) => setState(() {
                  _steps = v;
                  if (_step >= v) _step = v - 1;
                }),
              ),
            ],
          ),
        ),
        DemoPlayground(
          call: 'AnimatedCount',
          knobs: [
            ChoiceKnob<AppNumberFormat>(
              'format',
              _formats,
              apiDefaultCode: 'AppNumberFormats.count',
            ),
            ChoiceKnob<TextAlign?>('textAlign', const {
              'null': null,
              'TextAlign.center': TextAlign.center,
              'TextAlign.end': TextAlign.end,
            }, apiDefaultCode: 'null'),
          ],
          trailingCode: ['value: $_count'],
          builder: (context, k) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedCount(
                value: _count,
                format: k('format'),
                textAlign: k('textAlign'),
                style: context.textTheme.headlineMedium,
              ),
              12.heightBox,
              _CountRow(
                label: 'step',
                values: const [1, 250, 10000],
                value: _countStep,
                onChanged: (v) => setState(() => _countStep = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: '− $_countStep',
                      variant: AppButtonVariant.outlined,
                      onTap: () => setState(() => _count -= _countStep),
                    ),
                  ),
                  8.widthBox,
                  Expanded(
                    child: AppButton(
                      text: '+ $_countStep',
                      variant: AppButtonVariant.tonal,
                      onTap: () => setState(() => _count += _countStep),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoPlayground(
          call: 'PressableScale',
          knobs: [
            ChoiceKnob<double>(
              'scale',
              _scales,
              apiDefaultCode: 'AppMotion.pressedScale',
            ),
          ],
          trailingCode: const ['child: …'],
          builder: (context, k) => GestureDetector(
            onTap: () => setState(() => _presses++),
            child: PressableScale(
              scale: k('scale'),
              child: AppCard(
                variant: AppCardVariant.container,
                child: Column(
                  children: [
                    Icon(Icons.touch_app_outlined, color: colors.textMuted),
                    6.heightBox,
                    Text(
                      LocaleKeys.showcaseMotionPressHint.tr(),
                      style: context.textTheme.bodySmall,
                    ),
                    Text(
                      LocaleKeys.showcaseTypographyTapCount.tr(
                        args: ['$_presses'],
                      ),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        DemoBlock(
          code: _error == null
              ? 'ShakeOnError(error: null, child: …)'
              : "ShakeOnError(error: '…$_attempt', child: …)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShakeOnError(
                error: _error,
                child: AppCard(
                  variant: AppCardVariant.container,
                  child: Row(
                    children: [
                      Icon(
                        _error == null
                            ? Icons.lock_outline
                            : Icons.error_outline,
                        color: _error == null
                            ? colors.textMuted
                            : colors.feedbackError,
                      ),
                      8.widthBox,
                      Expanded(
                        child: Text(
                          _error ?? '••••',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: _error == null
                                ? colors.textSecondary
                                : colors.feedbackError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              12.heightBox,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.showcaseMotionShake.tr(),
                      variant: AppButtonVariant.tonal,
                      onTap: () => setState(() {
                        _attempt++;
                        // A new message each time — the same one does not
                        // shake twice.
                        _error = LocaleKeys.showcaseMotionShakeError.tr(
                          args: ['$_attempt'],
                        );
                      }),
                    ),
                  ),
                  8.widthBox,
                  Expanded(
                    child: AppButton(
                      text: LocaleKeys.clear.tr(),
                      variant: AppButtonVariant.outlined,
                      isEnabled: _error != null,
                      onTap: () => setState(() => _error = null),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppMotion.of(context)',
          // The switch stands in for the system setting on this card only.
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: _reduce),
            child: Builder(
              builder: (context) {
                final m = AppMotion.of(context);
                String ms(Duration d) => '${d.inMilliseconds} ms';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            LocaleKeys.showcaseMotionReduce.tr(),
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                        Switch.adaptive(
                          value: _reduce,
                          onChanged: (v) => setState(() => _reduce = v),
                        ),
                      ],
                    ),
                    Text(
                      LocaleKeys.showcaseMotionReduceHint.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    12.heightBox,
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (name, value) in [
                            ('.fast', ms(m.fast)),
                            ('.base', ms(m.base)),
                            ('.slow', ms(m.slow)),
                            ('.stagger', ms(m.stagger)),
                            ('.isReduced', '${m.isReduced}'),
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(color: colors.textMuted),
                                    ),
                                  ),
                                  Text(
                                    value,
                                    style: context.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    12.heightBox,
                    // The same counter under the setting: it jumps, not rolls.
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedCount(
                            value: _count,
                            style: context.textTheme.headlineSmall,
                          ),
                        ),
                        AppButton(
                          text: '+ $_countStep',
                          variant: AppButtonVariant.tonal,
                          size: AppButtonSize.small,
                          onTap: () => setState(() => _count += _countStep),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A few counts to choose from — an input of the demo, not of the widget.
class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.label,
    required this.values,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<int> values;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: context.textTheme.bodySmall),
      12.widthBox,
      Expanded(
        child: ChipRow<int>(
          items: values,
          labelResolver: (v) => '$v',
          selectedValue: value,
          onSelected: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    ],
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.of});

  final int step;
  final int of;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: AppCardVariant.container,
    child: Center(
      child: Text(
        '${LocaleKeys.showcaseStep.tr(args: ['${step + 1}'])} / $of',
        style: context.textTheme.headlineSmall,
      ),
    ),
  );
}
