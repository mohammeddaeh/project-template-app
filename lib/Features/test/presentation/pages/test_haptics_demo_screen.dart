import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/haptics/haptic_service.dart';
import 'package:app_template/presentation/extensions/app_padding_extension.dart';
import 'package:app_template/presentation/feedback/feedback_extension.dart';
import 'package:app_template/presentation/theme/theme_extensions.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/shared/widgets/widgets.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class TestHapticsDemoScreen extends StatefulWidget {
  const TestHapticsDemoScreen({super.key});

  @override
  State<TestHapticsDemoScreen> createState() => _TestHapticsDemoScreenState();
}

class _TestHapticsDemoScreenState extends State<TestHapticsDemoScreen> {
  final bool _enabled = AppFeatures.haptics &&
      GetIt.I.isRegistered<HapticService>();

  HapticService? get _haptics =>
      _enabled ? GetIt.I<HapticService>() : null;

  // Tracks last triggered haptic for visual feedback
  String? _lastTriggered;

  void _trigger(String label, void Function() fn) {
    fn();
    setState(() => _lastTriggered = label);
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.testHapticsDemoTitle.tr(),
          style: context.textTheme.headlineLarge,
        ),
      ),
      body: ListView(
        padding: 16.allPadding,
        children: [
          // ── Status Banner ────────────────────────────────────────────────────
          _StatusBanner(enabled: _enabled),
          24.heightBox,

          // ── Section 1: Direct Haptic Intensities ─────────────────────────────
          _SectionLabel(LocaleKeys.hapticTypes.tr()),
          12.heightBox,
          _HapticGrid(
            lastTriggered: _lastTriggered,
            items: [
              _HapticItem(
                label: LocaleKeys.hapticLight.tr(),
                hint: LocaleKeys.hapticLightHint.tr(),
                icon: Icons.touch_app_outlined,
                color: context.colorScheme.primary,
                onTap: _enabled
                    ? () => _trigger(
                        LocaleKeys.hapticLight.tr(),
                        () => _haptics!.light())
                    : null,
              ),
              _HapticItem(
                label: LocaleKeys.hapticMedium.tr(),
                hint: LocaleKeys.hapticMediumHint.tr(),
                icon: Icons.vibration_rounded,
                color: context.colorScheme.secondary,
                onTap: _enabled
                    ? () => _trigger(
                        LocaleKeys.hapticMedium.tr(),
                        () => _haptics!.medium())
                    : null,
              ),
              _HapticItem(
                label: LocaleKeys.hapticHeavy.tr(),
                hint: LocaleKeys.hapticHeavyHint.tr(),
                icon: Icons.bolt_rounded,
                color: context.colorScheme.error,
                onTap: _enabled
                    ? () => _trigger(
                        LocaleKeys.hapticHeavy.tr(),
                        () => _haptics!.heavy())
                    : null,
              ),
              _HapticItem(
                label: LocaleKeys.hapticSelection.tr(),
                hint: LocaleKeys.hapticSelectionHint.tr(),
                icon: Icons.radio_button_checked_rounded,
                color: context.colorScheme.tertiary,
                onTap: _enabled
                    ? () => _trigger(
                        LocaleKeys.hapticSelection.tr(),
                        () => _haptics!.selection())
                    : null,
              ),
            ],
          ),
          24.heightBox,

          // ── Section 2: Auto-integration via context.feedback.* ──────────────
          _SectionLabel(LocaleKeys.feedbackIntegration.tr()),
          8.heightBox,
          Text(
            'context.feedback.success() → haptic.medium()\n'
            'context.feedback.error() → haptic.heavy()\n'
            'context.feedback.info() → haptic.light()\n'
            'context.feedback.toast() → haptic.selection()',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          16.heightBox,
          _FeedbackRow(enabled: _enabled),
          32.heightBox,
        ],
      ),
    );
  }
}

// ── Status Banner ──────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: enabled ? Colors.green.shade600 : context.colorScheme.error,
            size: 22,
          ),
          12.widthBox,
          Expanded(
            child: Text(
              enabled
                  ? LocaleKeys.hapticEnabled.tr()
                  : LocaleKeys.hapticDisabled.tr(),
              style: context.textTheme.headlineSmall,
            ),
          ),
          if (enabled)
            Chip(
              label: Text(
                'AppFeatures.haptics = true',
                style: context.textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
              backgroundColor: context.colorScheme.primaryContainer,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: context.textTheme.headlineMedium,
      );
}

// ── Haptic Grid ───────────────────────────────────────────────────────────────

class _HapticGrid extends StatelessWidget {
  const _HapticGrid({required this.items, required this.lastTriggered});
  final List<_HapticItem> items;
  final String? lastTriggered;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((item) {
        final isActive = item.label == lastTriggered;
        return _HapticTile(item: item, isActive: isActive);
      }).toList(),
    );
  }
}

class _HapticItem {
  const _HapticItem({
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _HapticTile extends StatelessWidget {
  const _HapticTile({required this.item, required this.isActive});
  final _HapticItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive
            ? item.color.withValues(alpha: 0.18)
            : context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? item.color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item.icon, color: item.color, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: context.textTheme.headlineSmall),
                  Text(
                    item.hint,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feedback Row ──────────────────────────────────────────────────────────────

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FeedbackChip(
          label: LocaleKeys.success.tr(),
          icon: Icons.check_circle_outline,
          color: Colors.green.shade600,
          onTap: () => context.feedback.success(LocaleKeys.success.tr()),
        ),
        _FeedbackChip(
          label: LocaleKeys.error.tr(),
          icon: Icons.error_outline,
          color: context.colorScheme.error,
          onTap: () => context.feedback.error(LocaleKeys.somethingWrong.tr()),
        ),
        _FeedbackChip(
          label: LocaleKeys.warning.tr(),
          icon: Icons.warning_amber_outlined,
          color: Colors.orange.shade700,
          onTap: () => context.feedback.warning(LocaleKeys.warning.tr()),
        ),
        _FeedbackChip(
          label: LocaleKeys.info.tr(),
          icon: Icons.info_outline,
          color: context.colorScheme.primary,
          onTap: () => context.feedback.info(LocaleKeys.info.tr()),
        ),
        _FeedbackChip(
          label: LocaleKeys.toast.tr(),
          icon: Icons.notifications_none_rounded,
          color: context.colorScheme.secondary,
          onTap: () => context.feedback.toast(LocaleKeys.toastMessage.tr()),
        ),
      ],
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
