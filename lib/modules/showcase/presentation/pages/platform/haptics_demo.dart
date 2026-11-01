import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/core/platform/haptics/haptic_service.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// One button per [HapticService] kind. The service is registered only when
/// `AppFeatures.haptics` is on; without it the buttons stay disabled.
class HapticsDemo extends StatelessWidget {
  const HapticsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    final haptics = getIt.isRegistered<HapticService>()
        ? getIt<HapticService>()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code:
              'getIt<HapticService>().light() · medium() · heavy() · '
              'selection()',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'AppFeatures.haptics',
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  StatusChip(
                    labelText: '${AppFeatures.haptics}',
                    tone: AppFeatures.haptics
                        ? StatusTone.success
                        : StatusTone.neutral,
                  ),
                ],
              ),
              12.heightBox,
              Text(
                haptics == null
                    ? LocaleKeys.showcaseServicesUnavailable.tr(
                        args: ['haptics'],
                      )
                    : LocaleKeys.showcaseHapticsHint.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              12.heightBox,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (name, play) in <(String, void Function())>[
                    ('light', () => haptics?.light()),
                    ('medium', () => haptics?.medium()),
                    ('heavy', () => haptics?.heavy()),
                    ('selection', () => haptics?.selection()),
                  ])
                    AppButton(
                      text: name,
                      variant: AppButtonVariant.outlined,
                      isEnabled: haptics != null,
                      onTap: play,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
