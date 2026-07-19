import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/assets.gen.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/states/app_state_widget.dart';
import 'package:app_template/shared/widgets/widgets.dart';

enum _DemoState { loading, error, empty, noInternet, maintenance }

@RoutePage()
class TestStatesDemoScreen extends StatefulWidget {
  const TestStatesDemoScreen({super.key});

  @override
  State<TestStatesDemoScreen> createState() => _TestStatesDemoScreenState();
}

class _TestStatesDemoScreenState extends State<TestStatesDemoScreen> {
  _DemoState _current = _DemoState.empty;
  bool _withLottie = false;

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.testStatesDemoTitle.tr()),
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildCurrentState(context),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LottieToggleRow(
                  enabled: _withLottie,
                  onChanged: (v) => setState(() => _withLottie = v),
                ),
                const SizedBox(height: 12),
                Text(
                  LocaleKeys.selectState.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _DemoState.values.map((s) => FilterChip(
                    label: Text(_stateLabel(context, s)),
                    selected: s == _current,
                    onSelected: (_) => setState(() => _current = s),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentState(BuildContext context) {
    final lottie = _withLottie ? _lottieFor(_current) : null;

    return switch (_current) {
      _DemoState.loading => AppStateWidget(
          type: AppStateType.loading,
          lottieAsset: lottie,
        ),
      _DemoState.error => AppStateWidget(
          type: AppStateType.error,
          titleKey: LocaleKeys.somethingWrong,
          actionLabelKey: LocaleKeys.retry,
          onAction: () => context.feedback.toast(LocaleKeys.retry.tr()),
          lottieAsset: lottie,
        ),
      _DemoState.empty => AppStateWidget(
          type: AppStateType.empty,
          titleKey: LocaleKeys.noItems,
          lottieAsset: lottie,
        ),
      _DemoState.noInternet => AppStateWidget(
          type: AppStateType.noInternet,
          actionLabelKey: LocaleKeys.retry,
          onAction: () => context.feedback.toast(LocaleKeys.retry.tr()),
          lottieAsset: lottie,
        ),
      _DemoState.maintenance => AppStateWidget(
          type: AppStateType.maintenance,
          lottieAsset: lottie,
        ),
    };
  }

  String? _lottieFor(_DemoState s) => switch (s) {
    _DemoState.loading     => Assets.lottie.loading,
    _DemoState.error       => Assets.lottie.error,
    _DemoState.empty       => Assets.lottie.empty,
    _DemoState.noInternet  => Assets.lottie.noInternet,
    _DemoState.maintenance => Assets.lottie.maintenance,
  };

  String _stateLabel(BuildContext context, _DemoState s) => switch (s) {
    _DemoState.loading     => LocaleKeys.loading.tr(),
    _DemoState.error       => LocaleKeys.error.tr(),
    _DemoState.empty       => LocaleKeys.emptyState.tr(),
    _DemoState.noInternet  => LocaleKeys.noInternet.tr(),
    _DemoState.maintenance => LocaleKeys.maintenance.tr(),
  };
}

class _LottieToggleRow extends StatelessWidget {
  const _LottieToggleRow({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.animation_rounded,
          size: 18,
          color: enabled
              ? context.colorScheme.primary
              : context.colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            enabled
                ? LocaleKeys.withLottie.tr()
                : LocaleKeys.withIcon.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: enabled
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface,
              fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Switch.adaptive(value: enabled, onChanged: onChanged),
      ],
    );
  }
}
