import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/clipboard/clipboard_service.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/share/share_service.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// The clipboard and the share sheet. Each service is registered only when
/// its flag is on; without it the page says which flag to turn on.
class ServicesDemo extends StatelessWidget {
  const ServicesDemo({super.key});

  static T? _service<T extends Object>() =>
      getIt.isRegistered<T>() ? getIt<T>() : null;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    final clipboard = _service<ClipboardService>();
    final share = _service<ShareService>();
    final sample = LocaleKeys.showcaseServicesSample.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'getIt<ClipboardService>().copy(text) · paste() · hasText()',
          child: _ServiceCard(
            flag: 'clipboard',
            enabled: AppFeatures.clipboard,
            available: clipboard != null,
            actions: [
              AppButton(
                text: LocaleKeys.showcaseServicesCopy.tr(),
                leadingIcon: Icons.copy_rounded,
                isEnabled: clipboard != null,
                onTap: () async {
                  await clipboard?.copy(sample);
                  if (!context.mounted) return;
                  context.feedback.success(
                    LocaleKeys.showcaseServicesCopied.tr(),
                  );
                },
              ),
              AppButton(
                text: LocaleKeys.showcaseServicesPaste.tr(),
                leadingIcon: Icons.content_paste_rounded,
                variant: AppButtonVariant.outlined,
                isEnabled: clipboard != null,
                onTap: () async {
                  final text = await clipboard?.paste();
                  if (!context.mounted) return;
                  context.feedback.info(
                    (text == null || text.isEmpty)
                        ? LocaleKeys.showcaseServicesEmpty.tr()
                        : LocaleKeys.showcaseServicesPasted.tr(args: [text]),
                  );
                },
              ),
            ],
          ),
        ),
        DemoBlock(
          code: 'getIt<ShareService>().text(text, subject:) · url() · file()',
          child: _ServiceCard(
            flag: 'shareSheet',
            enabled: AppFeatures.shareSheet,
            available: share != null,
            actions: [
              AppButton(
                text: LocaleKeys.showcaseServicesShare.tr(),
                leadingIcon: Icons.share_rounded,
                isEnabled: share != null,
                onTap: () => share?.text(sample),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.flag,
    required this.enabled,
    required this.available,
    required this.actions,
  });

  final String flag;
  final bool enabled;
  final bool available;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'AppFeatures.$flag',
              style: context.textTheme.bodyMedium,
            ),
          ),
          StatusChip(
            labelKey: enabled
                ? LocaleKeys.showcaseFlagsOn
                : LocaleKeys.showcaseFlagsOff,
            tone: enabled ? StatusTone.success : StatusTone.neutral,
          ),
        ],
      ),
      if (!available) ...[
        const ResponsiveGap(8),
        Text(
          LocaleKeys.showcaseServicesUnavailable.tr(args: [flag]),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
      const ResponsiveGap(12),
      Wrap(spacing: 8, runSpacing: 8, children: actions),
    ],
  );
}
