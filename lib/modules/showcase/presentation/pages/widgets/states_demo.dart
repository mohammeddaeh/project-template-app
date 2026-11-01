import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/playground_tokens.dart';
import 'package:app_template/resources/assets.gen.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The screen states a list or detail page shows while it waits, fails or
/// finds nothing — the progress widget in its shapes, the skeletons, and the
/// fallback a broken widget draws.
class StatesDemo extends StatefulWidget {
  const StatesDemo({super.key});

  @override
  State<StatesDemo> createState() => _StatesDemoState();
}

/// The named shortcuts over [AppStateWidget] — one box renders the picked one.
enum _Shortcut {
  loadingWidget,
  emptyStateWidget,
  errorStateWidget,
  noInternetWidget,
  maintenanceWidget,
  successStateWidget,
  warningStateWidget,
  infoStateWidget,
}

class _StatesDemoState extends State<StatesDemo> {
  bool _waiting = true;
  _Shortcut _shortcut = _Shortcut.noInternetWidget;

  void _retried() =>
      context.feedback.info(LocaleKeys.showcaseStatesRetried.tr());

  Widget _shortcutFor(_Shortcut s) => switch (s) {
    _Shortcut.loadingWidget => const LoadingWidget(),
    _Shortcut.emptyStateWidget => const EmptyStateWidget(
      titleKey: LocaleKeys.noDataFound,
    ),
    _Shortcut.errorStateWidget => ErrorStateWidget(
      messageKey: LocaleKeys.somethingWrong,
      onRetry: _retried,
    ),
    _Shortcut.noInternetWidget => NoInternetWidget(onRetry: _retried),
    _Shortcut.maintenanceWidget => const MaintenanceWidget(),
    _Shortcut.successStateWidget => const SuccessStateWidget(
      messageKey: LocaleKeys.showcaseStatesSaved,
    ),
    _Shortcut.warningStateWidget => const WarningStateWidget(
      messageKey: LocaleKeys.showcaseStatesStorageLow,
    ),
    _Shortcut.infoStateWidget => const InfoStateWidget(
      messageKey: LocaleKeys.showcaseStatesSyncLater,
    ),
  };

  static String _typeName(_Shortcut s) =>
      '${s.name[0].toUpperCase()}${s.name.substring(1)}';

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final name = LocaleKeys.showcaseItem.tr(args: ['3']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DemoBlock(
          code: 'AppProgress.circular · AppProgress.linear',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                children: [
                  AppProgress.circular(size: AppProgressSize.sm),
                  AppProgress.circular(),
                  AppProgress.circular(value: 0.65),
                ],
              ),
              SizedBox(height: 16),
              AppProgress.linear(value: 0.4),
            ],
          ),
        ),
        DemoBlock(
          code:
              'Skeletonized(enabled: …, child: <the real body>)'
              ' · Bone · ShimmerText',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(LocaleKeys.showcaseStatesSimulateLoading.tr()),
                value: _waiting,
                onChanged: (v) => setState(() => _waiting = v),
              ),
              Skeletonized(
                enabled: _waiting,
                child: Row(
                  children: [
                    AvatarWidget(initial: name),
                    12.widthBox,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerText(
                            name,
                            style: context.textTheme.titleSmall,
                          ),
                          4.heightBox,
                          ShimmerText(
                            LocaleKeys.showcaseDisplaySubtitle.tr(),
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Bone(
                      radius: 12,
                      child: StatusChip(
                        labelKey: LocaleKeys.showcaseDisplayOpen,
                        tone: StatusTone.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── AppStateWidget ──────────────────────────────────────────────────
        DemoPlayground(
          call: 'AppStateWidget',
          knobs: [
            EnumKnob(
              'type',
              AppStateType.values,
              AppStateType.empty,
              required: true,
            ),
            // null = the type's own title, where it has one.
            ChoiceKnob<String?>(
              'titleKey',
              const {
                'null': null,
                'LocaleKeys.showcaseStatesEmptyTitle':
                    LocaleKeys.showcaseStatesEmptyTitle,
                'LocaleKeys.somethingWrong': LocaleKeys.somethingWrong,
              },
              initialCode: 'LocaleKeys.showcaseStatesEmptyTitle',
              apiDefaultCode: 'null',
            ),
            ChoiceKnob<String?>(
              'descriptionKey',
              const {
                'null': null,
                'LocaleKeys.showcaseStatesEmptyHint':
                    LocaleKeys.showcaseStatesEmptyHint,
              },
              initialCode: 'LocaleKeys.showcaseStatesEmptyHint',
              apiDefaultCode: 'null',
            ),
            // The button shows only with both a label and an action.
            ChoiceKnob<String?>('actionLabelKey', const {
              'null': null,
              'LocaleKeys.retry': LocaleKeys.retry,
              'LocaleKeys.showcaseAdd': LocaleKeys.showcaseAdd,
            }, apiDefaultCode: 'null'),
            callbackKnob('onAction', code: '() => toast(…)', initial: false),
            ChoiceKnob<IconData?>('icon', const {
              'null': null,
              'Icons.search_off': Icons.search_off,
              'Icons.cloud_off_outlined': Icons.cloud_off_outlined,
            }, apiDefaultCode: 'null'),
            ChoiceKnob<double?>('iconSize', const {
              'null': null,
              '40': 40,
              '88': 88,
            }, apiDefaultCode: 'null'),
            colorKnob('iconColor', const ['secondary', 'error']),
            // Replaces the icon when given.
            ChoiceKnob<String?>('lottieAsset', {
              'null': null,
              'Assets.lottie.empty': Assets.lottie.empty,
              'Assets.lottie.error': Assets.lottie.error,
              'Assets.lottie.success': Assets.lottie.success,
            }, apiDefaultCode: 'null'),
          ],
          builder: (context, k) => SizedBox(
            height: 300,
            child: AppStateWidget(
              type: k('type'),
              titleKey: k('titleKey'),
              descriptionKey: k('descriptionKey'),
              actionLabelKey: k('actionLabelKey'),
              onAction: k('onAction') ? _retried : null,
              icon: k('icon'),
              iconSize: k('iconSize'),
              iconColor: tokenColor(context, k('iconColor')),
              lottieAsset: k('lottieAsset'),
              lottieSize: 120,
            ),
          ),
        ),
        DemoBlock(
          code: '${_typeName(_shortcut)}(…) — a named AppStateWidget',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<_Shortcut>(
                items: _Shortcut.values,
                labelResolver: _typeName,
                selectedValue: _shortcut,
                onSelected: (s) => setState(() => _shortcut = s ?? _shortcut),
              ),
              SizedBox(height: 220, child: _shortcutFor(_shortcut)),
            ],
          ),
        ),
        DemoBlock(
          code: 'RetryWidget(onRetry: …)',
          child: Center(child: RetryWidget(onRetry: _retried)),
        ),
        const DemoBlock(
          code: 'PlaceholderScreen(titleKey: …, icon: …)',
          child: SizedBox(
            height: 300,
            child: PlaceholderScreen(
              titleKey: LocaleKeys.showcaseDisplayTitle,
              icon: Icons.construction_outlined,
            ),
          ),
        ),
        // ── The skeleton family ─────────────────────────────────────────────
        const _SkeletonPlayground(),
        DemoBlock(
          code:
              'ErrorBoundary.install() → ErrorFallback(details: …, '
              'debugOverride: true / false)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final debug in [true, false]) ...[
                SizedBox(
                  height: 180,
                  child: ErrorFallback(
                    debugOverride: debug,
                    details: FlutterErrorDetails(
                      exception: StateError(
                        LocaleKeys.showcaseStatesSampleError.tr(),
                      ),
                    ),
                  ),
                ),
                8.heightBox,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The ready-made skeletons, one picked at a time, each with its own options.
enum _Skeleton {
  skeletonListTile,
  skeletonCard,
  skeletonGridItem,
  skeletonProfile,
  skeletonStatRow,
  skeletonWidget,
  shimmerLoadingWidget,
}

class _SkeletonPlayground extends StatefulWidget {
  const _SkeletonPlayground();

  @override
  State<_SkeletonPlayground> createState() => _SkeletonPlaygroundState();
}

class _SkeletonPlaygroundState extends State<_SkeletonPlayground> {
  _Skeleton _kind = _Skeleton.skeletonListTile;

  static String _className(_Skeleton s) =>
      '${s.name[0].toUpperCase()}${s.name.substring(1)}';

  /// Their default padding is a page gutter — the card already has one.
  static ChoiceKnob<bool> _padding() => ChoiceKnob<bool>(
    'padding',
    const {'null': false, 'EdgeInsets.zero': true},
    initialCode: 'EdgeInsets.zero',
    apiDefaultCode: 'null',
  );

  static EdgeInsets? _pad(KnobValues k) =>
      k('padding') ? EdgeInsets.zero : null;

  static NumberKnob _lines(double apiDefault) => NumberKnob(
    'lines',
    initial: apiDefault,
    min: 1,
    max: 3,
    integer: true,
    apiDefault: apiDefault,
  );

  DemoPlayground _playground() => switch (_kind) {
    _Skeleton.skeletonListTile => DemoPlayground(
      call: 'SkeletonListTile',
      knobs: [
        const BoolKnob('showAvatar', initial: true, apiDefault: true),
        _lines(2),
        _padding(),
      ],
      builder: (context, k) => SkeletonListTile(
        showAvatar: k('showAvatar'),
        lines: k<double>('lines').round(),
        padding: _pad(k),
      ),
    ),
    _Skeleton.skeletonCard => DemoPlayground(
      call: 'SkeletonCard',
      knobs: [
        const BoolKnob('showImage', initial: true, apiDefault: true),
        const NumberKnob(
          'imageHeight',
          initial: 100,
          min: 60,
          max: 200,
          integer: true,
          apiDefault: 140,
        ),
        _lines(3),
        _padding(),
      ],
      builder: (context, k) => SkeletonCard(
        showImage: k('showImage'),
        imageHeight: k('imageHeight'),
        lines: k<double>('lines').round(),
        padding: _pad(k),
      ),
    ),
    _Skeleton.skeletonGridItem => DemoPlayground(
      call: 'SkeletonGridItem',
      knobs: [
        const NumberKnob(
          'aspectRatio',
          initial: 0.85,
          min: 0.5,
          max: 1.5,
          divisions: 10,
          apiDefault: 0.85,
        ),
        _padding(),
      ],
      builder: (context, k) => SizedBox(
        width: 160,
        child: SkeletonGridItem(
          aspectRatio: k('aspectRatio'),
          padding: _pad(k),
        ),
      ),
    ),
    _Skeleton.skeletonProfile => DemoPlayground(
      call: 'SkeletonProfile',
      knobs: [
        const NumberKnob(
          'avatarRadius',
          initial: 40,
          min: 20,
          max: 60,
          integer: true,
          apiDefault: 40,
        ),
        _lines(3),
        _padding(),
      ],
      builder: (context, k) => SkeletonProfile(
        avatarRadius: k('avatarRadius'),
        lines: k<double>('lines').round(),
        padding: _pad(k),
      ),
    ),
    _Skeleton.skeletonStatRow => DemoPlayground(
      call: 'SkeletonStatRow',
      knobs: [
        const NumberKnob(
          'count',
          initial: 3,
          min: 2,
          max: 6,
          integer: true,
          apiDefault: 3,
        ),
        _padding(),
      ],
      builder: (context, k) =>
          SkeletonStatRow(count: k<double>('count').round(), padding: _pad(k)),
    ),
    _Skeleton.skeletonWidget => DemoPlayground(
      call: 'SkeletonWidget',
      knobs: const [
        NumberKnob('width', initial: 180, min: 40, max: 280, integer: true),
        NumberKnob(
          'height',
          initial: 16,
          min: 8,
          max: 64,
          integer: true,
          apiDefault: 16,
        ),
        NumberKnob(
          'borderRadius',
          initial: 4,
          min: 0,
          max: 32,
          integer: true,
          apiDefault: 4,
        ),
      ],
      builder: (context, k) => SkeletonWidget(
        width: k('width'),
        height: k('height'),
        borderRadius: k('borderRadius'),
      ),
    ),
    _Skeleton.shimmerLoadingWidget => DemoPlayground(
      call: 'ShimmerLoadingWidget',
      knobs: [
        colorKnob('baseColor', const ['borderSubtle', 'primaryContainer']),
        colorKnob('highlightColor', const ['bgNeutral', 'onBrand']),
      ],
      trailingCode: const ['child: Container(…)'],
      builder: (context, k) => ShimmerLoadingWidget(
        baseColor: tokenColor(context, k('baseColor')),
        highlightColor: tokenColor(context, k('highlightColor')),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: context.colors.borderSubtle,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: ChipRow<_Skeleton>(
          items: _Skeleton.values,
          labelResolver: _className,
          selectedValue: _kind,
          onSelected: (s) => setState(() => _kind = s ?? _kind),
        ),
      ),
      8.heightBox,
      // A new kind is a new set of controls — start it afresh.
      KeyedSubtree(key: ValueKey(_kind), child: _playground()),
    ],
  );
}
