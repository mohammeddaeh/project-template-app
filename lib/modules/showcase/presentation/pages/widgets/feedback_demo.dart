import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/call_playground.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback.dart';
import 'package:app_template/ui/feedback/feedback_style.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `context.feedback` as a playground — the message type, the adapter, a
/// title, an action and how long it stays — then every progress and loading
/// indicator with its options.
class FeedbackDemo extends StatelessWidget {
  const FeedbackDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeedbackPlayground(),
        DemoBlock(
          code: 'toast ≠ EmptyStateWidget / ErrorStateWidget',
          child: Text(
            LocaleKeys.showcaseFeedbackWhen.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            LocaleKeys.showcaseIndicators.tr(),
            style: context.textTheme.titleMedium,
          ),
        ),
        const _Indicators(),
      ],
    );
  }
}

/// The calls of `context.feedback`: one per type, plus `toast`.
enum _Kind { success, error, warning, info, toast }

/// One "show" button for every combination. The call written above it
/// follows the choice: an action goes through `show(FeedbackConfig(…))`,
/// which has no `style`; `toast` takes `seconds` and no title.
class _FeedbackPlayground extends StatelessWidget {
  const _FeedbackPlayground();

  static const _durations = <String, Duration?>{
    'null': null,
    'const Duration(seconds: 1)': Duration(seconds: 1),
    'const Duration(seconds: 6)': Duration(seconds: 6),
  };

  static String _quote(String s) => "'${s.replaceAll("'", r"\'")}'";

  static List<String> _ignored(CallArgs a) {
    final kind = a<_Kind>('method');
    final withAction = a<bool>('action');
    return [
      if (kind == _Kind.toast && (a<String>('title')).isNotEmpty) 'title',
      if (kind == _Kind.toast && withAction) 'action',
      if (kind != _Kind.toast && withAction && a('style') != null) 'style',
    ];
  }

  static String _code(CallArgs a) {
    final kind = a<_Kind>('method');
    final String message = a('message');
    final String title = a('title');
    final Duration? duration = a('duration');
    final FeedbackStyle? style = a('style');

    if (kind == _Kind.toast) {
      return writeCall('context.feedback.toast', [
        _quote(message),
        if (duration != null) 'seconds: ${duration.inSeconds}',
        if (style != null) 'style: FeedbackStyle.${style.name}',
      ]);
    }
    if (a<bool>('action')) {
      return writeCall('context.feedback.show', [
        writeCall('FeedbackConfig', [
          'type: FeedbackType.${kind.name}',
          'message: ${_quote(message)}',
          if (title.isNotEmpty) 'title: ${_quote(title)}',
          if (duration != null)
            'duration: ${_durations.keys.firstWhere((c) => _durations[c] == duration)}',
          'action: FeedbackAction(label: LocaleKeys.retry.tr(), onTap: …)',
        ]),
      ]);
    }
    return writeCall('context.feedback.${kind.name}', [
      _quote(message),
      ...a.named(skip: {'method', 'message', 'action'}),
    ]);
  }

  void _show(BuildContext context, CallArgs a) {
    final f = context.feedback;
    final kind = a<_Kind>('method');
    final String message = a('message');
    final String rawTitle = a('title');
    final title = rawTitle.isEmpty ? null : rawTitle;
    final Duration? duration = a('duration');
    final FeedbackStyle? style = a('style');

    if (kind == _Kind.toast) {
      f.toast(message, seconds: duration?.inSeconds ?? 3, style: style);
      return;
    }
    if (a<bool>('action')) {
      f.show(
        FeedbackConfig(
          type: FeedbackType.values.byName(kind.name),
          message: message,
          title: title,
          duration: duration,
          action: FeedbackAction(
            label: LocaleKeys.retry.tr(),
            onTap: () => f.toast(LocaleKeys.showcaseFeedbackSoon.tr()),
          ),
        ),
      );
      return;
    }
    final call = switch (kind) {
      _Kind.success => f.success,
      _Kind.error => f.error,
      _Kind.warning => f.warning,
      _Kind.info || _Kind.toast => f.info,
    };
    call(message, title: title, duration: duration, style: style);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    // The messages go through the adapter registered in DI; without it (a
    // widget test, a build that left it out) the button says so instead of
    // throwing.
    final ready = getIt.isRegistered<AppFeedbackService>();

    return CallPlayground(
      knobs: [
        EnumKnob('method', _Kind.values, _Kind.success, typeName: 'method'),
        TextKnob(
          'message',
          initial: LocaleKeys.showcaseFeedbackSaved.tr(),
          required: true,
        ),
        // Empty = not passed.
        const TextKnob('title', initial: '', apiDefault: ''),
        ChoiceKnob<Duration?>('duration', _durations, apiDefaultCode: 'null'),
        ChoiceKnob<FeedbackStyle?>('style', const {
          'null': null,
          'FeedbackStyle.motionToast': FeedbackStyle.motionToast,
          'FeedbackStyle.snackbar': FeedbackStyle.snackbar,
          'FeedbackStyle.simpleToast': FeedbackStyle.simpleToast,
        }, apiDefaultCode: 'null'),
        ChoiceKnob<bool>('action', const {
          'null': false,
          'FeedbackAction(label: …, onTap: …)': true,
        }, apiDefaultCode: 'null'),
      ],
      code: _code,
      builder: (context, a) {
        final ignored = _ignored(a);
        return Column(
          children: [
            AppButton(
              text: LocaleKeys.showcaseFeedbackShow.tr(),
              leadingIcon: Icons.notifications_active_outlined,
              isEnabled: ready,
              onTap: () => _show(context, a),
            ),
            if (ignored.isNotEmpty) ...[
              8.heightBox,
              Text(
                LocaleKeys.showcaseFeedbackIgnored.tr(
                  args: [ignored.join(', ')],
                ),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ],
            if (!ready) ...[
              8.heightBox,
              Text(
                LocaleKeys.showcaseFeedbackNoService.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.stateError,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Progress bars, spinners, the status ring and the first-load placeholders —
/// each with its options.
class _Indicators extends StatelessWidget {
  const _Indicators();

  static const _centers = <String, Widget?>{
    'null': null,
    'Icon(Icons.check_rounded, size: 16)': Icon(Icons.check_rounded, size: 16),
  };

  /// `onBrand` is drawn for a brand surface — show it on one.
  static Widget _onSurface(
    BuildContext context,
    AppProgressTone tone,
    Widget child,
  ) => ColoredBox(
    color: tone == AppProgressTone.onBrand
        ? context.colors.bgBrand
        : Colors.transparent,
    child: Padding(padding: 12.allPadding, child: child),
  );

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoPlayground(
          call: 'AppProgress.circular',
          knobs: [
            const OptionalNumberKnob('value', initial: 0.65, whenOn: 0.65),
            EnumKnob('tone', AppProgressTone.values, AppProgressTone.brand),
            EnumKnob('size', AppProgressSize.values, AppProgressSize.md),
            ChoiceKnob<Widget?>('center', _centers, apiDefaultCode: 'null'),
            const BoolKnob('adaptive'),
            const BoolKnob('animate', initial: true, apiDefault: true),
          ],
          builder: (context, k) => _onSurface(
            context,
            k('tone'),
            AppProgress.circular(
              value: k('value'),
              tone: k('tone'),
              size: k('size'),
              center: k('center'),
              adaptive: k('adaptive'),
              animate: k('animate'),
            ),
          ),
        ),
        DemoPlayground(
          call: 'AppProgress.linear',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: [
            const OptionalNumberKnob('value', initial: 0.4, whenOn: 0.4),
            EnumKnob('tone', AppProgressTone.values, AppProgressTone.brand),
            EnumKnob('size', AppProgressSize.values, AppProgressSize.md),
            TextKnob(
              'label',
              initial: LocaleKeys.showcaseIndicatorsCount.tr(
                args: ['32', '80', '40'],
              ),
              // Empty = not passed.
              apiDefault: '',
            ),
            const BoolKnob('animate', initial: true, apiDefault: true),
          ],
          builder: (context, k) {
            final String label = k('label');
            return _onSurface(
              context,
              k('tone'),
              AppProgress.linear(
                value: k('value'),
                tone: k('tone'),
                size: k('size'),
                label: label.isEmpty ? null : label,
                animate: k('animate'),
              ),
            );
          },
        ),
        DemoPlayground(
          call: 'ProgressWithCount',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: const [
            NumberKnob(
              'progress',
              initial: 0.65,
              min: 0,
              max: 1,
              divisions: 20,
              required: true,
            ),
            NumberKnob(
              'height',
              initial: 7,
              min: 2,
              max: 16,
              divisions: 14,
              apiDefault: 7,
            ),
          ],
          trailingCode: const [
            "label: LocaleKeys.….tr(args: ['\$done', '\$total', '\$pct'])",
          ],
          builder: (context, k) {
            const total = 80;
            final double progress = k('progress');
            return ProgressWithCount(
              progress: progress,
              height: k('height'),
              label: LocaleKeys.showcaseIndicatorsCount.tr(
                args: [
                  '${(progress * total).round()}',
                  '$total',
                  '${(progress * 100).round()}',
                ],
              ),
            );
          },
        ),
        DemoPlayground(
          call: 'ProgressIndicatorWidget',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: const [
            OptionalNumberKnob('value', initial: 0.4, whenOn: 0.4),
            BoolKnob('linear', initial: true, apiDefault: true),
          ],
          builder: (context, k) =>
              ProgressIndicatorWidget(value: k('value'), linear: k('linear')),
        ),
        const DemoBlock(
          code: 'AppLoader()',
          child: SizedBox(height: 48, child: AppLoader()),
        ),
        DemoPlayground(
          call: 'StatusFeedbackIndicator',
          knobs: [
            EnumKnob('tone', StatusTone.values, StatusTone.neutral),
            const BoolKnob('isLoading'),
            const NumberKnob(
              'size',
              initial: 64,
              min: 32,
              max: 120,
              divisions: 11,
              apiDefault: 64,
            ),
          ],
          builder: (context, k) => StatusFeedbackIndicator(
            tone: k('tone'),
            isLoading: k('isLoading'),
            size: k('size'),
          ),
        ),
        DemoPlayground(
          call: 'InitialLoadingIndicator',
          previewAlignment: AlignmentDirectional.topStart,
          knobs: [
            EnumKnob(
              'style',
              InitialLoadingStyle.values,
              InitialLoadingStyle.spinner,
            ),
            const NumberKnob(
              'itemCount',
              initial: 4,
              min: 1,
              max: 8,
              integer: true,
              apiDefault: 6,
            ),
          ],
          builder: (context, k) => SizedBox(
            height: 260,
            child: InitialLoadingIndicator(
              style: k('style'),
              itemCount: k<double>('itemCount').round(),
            ),
          ),
        ),
      ],
    );
  }
}
