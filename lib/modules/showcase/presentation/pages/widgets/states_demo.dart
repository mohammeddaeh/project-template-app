import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
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
  AppStateType _type = AppStateType.empty;
  _Shortcut _shortcut = _Shortcut.noInternetWidget;

  void _retried() =>
      context.feedback.info(LocaleKeys.showcaseStatesRetried.tr());

  Widget _stateFor(AppStateType type) => AppStateWidget(
    type: type,
    titleKey: type == AppStateType.empty
        ? LocaleKeys.showcaseStatesEmptyTitle
        : type == AppStateType.error
        ? LocaleKeys.somethingWrong
        : null,
    descriptionKey: type == AppStateType.empty
        ? LocaleKeys.showcaseStatesEmptyHint
        : null,
    actionLabelKey: type == AppStateType.error ? LocaleKeys.retry : null,
    onAction: type == AppStateType.error ? _retried : null,
  );

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
                    Bone(
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
        DemoBlock(
          code: 'AppStateWidget(type: AppStateType.…)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipRow<AppStateType>(
                items: AppStateType.values,
                labelResolver: (t) => t.name,
                selectedValue: _type,
                onSelected: (t) => setState(() => _type = t ?? _type),
              ),
              SizedBox(height: 240, child: _stateFor(_type)),
            ],
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
        DemoBlock(
          code: 'ShimmerLoadingWidget(child: …) · SkeletonWidget',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoadingWidget(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.borderSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              12.heightBox,
              const SkeletonWidget(width: 180),
              8.heightBox,
              const SkeletonWidget(width: 120, height: 12, borderRadius: 6),
            ],
          ),
        ),
        const DemoBlock(
          code: 'SkeletonListTile(showAvatar: …, lines: 1–3)',
          child: Column(
            children: [
              SkeletonListTile(padding: EdgeInsets.zero),
              SizedBox(height: 12),
              SkeletonListTile(
                showAvatar: false,
                lines: 3,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const DemoBlock(
          code: 'SkeletonCard(showImage: …, imageHeight: …)',
          child: SkeletonCard(imageHeight: 100, padding: EdgeInsets.zero),
        ),
        const DemoBlock(
          code: 'SkeletonGridItem(aspectRatio: …)',
          child: Row(
            children: [
              Expanded(child: SkeletonGridItem()),
              Expanded(child: SkeletonGridItem()),
              Expanded(child: SkeletonGridItem()),
            ],
          ),
        ),
        const DemoBlock(
          code: 'SkeletonProfile(avatarRadius: …) · SkeletonStatRow(count: …)',
          child: Column(
            children: [
              SkeletonProfile(avatarRadius: 32),
              SkeletonStatRow(padding: EdgeInsets.zero),
            ],
          ),
        ),
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
