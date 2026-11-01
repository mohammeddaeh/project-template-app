import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/feedback/feedback_style.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `context.feedback.*` — one button per message type, the adapter to show it
/// with — then the progress and loading indicators.
class FeedbackDemo extends StatefulWidget {
  const FeedbackDemo({super.key});

  @override
  State<FeedbackDemo> createState() => _FeedbackDemoState();
}

class _FeedbackDemoState extends State<FeedbackDemo> {
  /// `null` = the adapter registered in DI.
  FeedbackStyle? _style;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    // The messages go through the adapter registered in DI; without it (a
    // widget test, a build that left it out) the buttons say so instead of
    // throwing.
    final ready = getIt.isRegistered<AppFeedbackService>();
    final f = context.feedback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'context.feedback.success / error / warning / info / toast',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'style: FeedbackStyle.…',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ),
              8.heightBox,
              ChipRow<FeedbackStyle>(
                items: FeedbackStyle.values,
                labelResolver: (s) => s.name,
                selectedValue: _style,
                onSelected: (s) => setState(() => _style = s),
              ),
              12.heightBox,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton(
                    text: LocaleKeys.success.tr(),
                    isEnabled: ready,
                    onTap: () => f.success(
                      LocaleKeys.showcaseFeedbackSaved.tr(),
                      style: _style,
                    ),
                  ),
                  AppButton(
                    text: LocaleKeys.error.tr(),
                    variant: AppButtonVariant.danger,
                    isEnabled: ready,
                    onTap: () => f.error(
                      LocaleKeys.showcaseFeedbackFailed.tr(),
                      style: _style,
                    ),
                  ),
                  AppButton(
                    text: LocaleKeys.warning.tr(),
                    variant: AppButtonVariant.tonal,
                    isEnabled: ready,
                    onTap: () => f.warning(
                      LocaleKeys.showcaseFeedbackSlow.tr(),
                      style: _style,
                    ),
                  ),
                  AppButton(
                    text: LocaleKeys.info.tr(),
                    variant: AppButtonVariant.outlined,
                    isEnabled: ready,
                    onTap: () => f.info(
                      LocaleKeys.showcaseFeedbackSoon.tr(),
                      style: _style,
                    ),
                  ),
                  AppButton(
                    text: LocaleKeys.showcaseFeedbackToast.tr(),
                    variant: AppButtonVariant.text,
                    isEnabled: ready,
                    onTap: () => f.toast(
                      LocaleKeys.showcaseFeedbackCopied.tr(),
                      style: _style,
                    ),
                  ),
                ],
              ),
              if (!ready) ...[
                12.heightBox,
                Text(
                  LocaleKeys.showcaseFeedbackNoService.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.stateError,
                  ),
                ),
              ],
            ],
          ),
        ),
        DemoBlock(
          code:
              'context.feedback.show(FeedbackConfig(type: …, message: …, '
              'action: FeedbackAction(label: …, onTap: …)))',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              text: LocaleKeys.showcaseFeedbackWithAction.tr(),
              variant: AppButtonVariant.outlined,
              isEnabled: ready,
              onTap: () => f.show(
                FeedbackConfig(
                  type: FeedbackType.error,
                  message: LocaleKeys.showcaseFeedbackFailed.tr(),
                  action: FeedbackAction(
                    label: LocaleKeys.retry.tr(),
                    onTap: () => f.toast(LocaleKeys.showcaseFeedbackSoon.tr()),
                  ),
                ),
              ),
            ),
          ),
        ),
        DemoBlock(
          code: 'toast ≠ EmptyStateWidget / ErrorStateWidget',
          child: Text(
            LocaleKeys.showcaseFeedbackWhen.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const _Indicators(),
      ],
    );
  }
}

/// Progress bars, spinners, the status ring and the first-load placeholders.
class _Indicators extends StatefulWidget {
  const _Indicators();

  @override
  State<_Indicators> createState() => _IndicatorsState();
}

class _IndicatorsState extends State<_Indicators> {
  static const _total = 80;
  int _done = 52;
  StatusTone _tone = StatusTone.neutral;
  bool _busy = false;
  InitialLoadingStyle _initial = InitialLoadingStyle.spinner;

  double get _progress => _done / _total;

  void _step() => setState(() => _done = _done >= _total ? 0 : _done + 14);

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    final done = _done.clamp(0, _total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            LocaleKeys.showcaseIndicators.tr(),
            style: context.textTheme.titleMedium,
          ),
        ),
        DemoBlock(
          code: 'ProgressWithCount(progress: …, label: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressWithCount(
                progress: _progress,
                label: LocaleKeys.showcaseIndicatorsCount.tr(
                  args: ['$done', '$_total', '${(_progress * 100).round()}'],
                ),
              ),
              12.heightBox,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  text: LocaleKeys.showcaseNext.tr(),
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.tonal,
                  onTap: _step,
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'ProgressIndicatorWidget(value: …, linear: true | false)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressIndicatorWidget(value: _progress),
              16.heightBox,
              const ProgressIndicatorWidget(),
              16.heightBox,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ProgressIndicatorWidget(value: _progress, linear: false),
                  const ProgressIndicatorWidget(linear: false),
                ],
              ),
            ],
          ),
        ),
        const DemoBlock(
          code: 'AppLoader()',
          child: SizedBox(height: 48, child: AppLoader()),
        ),
        DemoBlock(
          code: 'StatusFeedbackIndicator(tone: StatusTone.…, isLoading: …)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: StatusFeedbackIndicator(tone: _tone, isLoading: _busy),
              ),
              16.heightBox,
              ChipRow<StatusTone>(
                items: StatusTone.values,
                labelResolver: (t) => t.name,
                selectedValue: _tone,
                onSelected: (t) => setState(() => _tone = t ?? _tone),
              ),
              8.heightBox,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  text: LocaleKeys.showcaseIndicatorsLoading.tr(),
                  size: AppButtonSize.small,
                  variant: _busy
                      ? AppButtonVariant.filled
                      : AppButtonVariant.outlined,
                  onTap: () => setState(() => _busy = !_busy),
                ),
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'InitialLoadingIndicator(style: InitialLoadingStyle.…)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<InitialLoadingStyle>(
                items: InitialLoadingStyle.values,
                labelResolver: (s) => s.name,
                selectedValue: _initial,
                onSelected: (s) => setState(() => _initial = s ?? _initial),
              ),
              12.heightBox,
              SizedBox(
                height: 260,
                child: InitialLoadingIndicator(style: _initial, itemCount: 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
