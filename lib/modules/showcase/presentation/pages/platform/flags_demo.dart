import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/core/platform/features/app_features.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Every `AppFeatures` flag with the value this build was compiled with,
/// grouped by what it switches on.
class FlagsDemo extends StatelessWidget {
  const FlagsDemo({super.key});

  static const _groups = <(String, List<(String, bool)>)>[
    (
      LocaleKeys.showcaseFlagsAccount,
      [
        ('debugSkipLogin', AppFeatures.debugSkipLogin),
        ('rememberedAccounts', AppFeatures.rememberedAccounts),
        ('sessionGuard', AppFeatures.sessionGuard),
        ('biometrics', AppFeatures.biometrics),
        ('multiDevice', AppFeatures.multiDevice),
      ],
    ),
    (
      LocaleKeys.showcaseFlagsModules,
      [
        ('offlineSync', AppFeatures.offlineSync),
        ('dataTransfer', AppFeatures.dataTransfer),
        ('accessControl', AppFeatures.accessControl),
        ('notificationCenter', AppFeatures.notificationCenter),
        ('inAppUpdates', AppFeatures.inAppUpdates),
        ('showcase', AppFeatures.showcase),
      ],
    ),
    (
      LocaleKeys.showcaseFlagsPlatform,
      [
        ('clipboard', AppFeatures.clipboard),
        ('shareSheet', AppFeatures.shareSheet),
        ('fileOperations', AppFeatures.fileOperations),
        ('appLifecycle', AppFeatures.appLifecycle),
        ('haptics', AppFeatures.haptics),
        ('localNotifications', AppFeatures.localNotifications),
        ('pushNotifications', AppFeatures.pushNotifications),
      ],
    ),
    (
      LocaleKeys.showcaseFlagsPermissions,
      [
        ('camera', AppFeatures.camera),
        ('microphone', AppFeatures.microphone),
        ('location', AppFeatures.location),
        ('locationAlways', AppFeatures.locationAlways),
        ('photos', AppFeatures.photos),
        ('fileStorage', AppFeatures.fileStorage),
        ('contacts', AppFeatures.contacts),
        ('bluetooth', AppFeatures.bluetooth),
      ],
    ),
    (
      LocaleKeys.showcaseFlagsObservability,
      [
        ('crashReporting', AppFeatures.crashReporting),
        ('analytics', AppFeatures.analytics),
        ('remoteConfig', AppFeatures.remoteConfig),
        ('verboseNetworkLog', AppFeatures.verboseNetworkLog),
      ],
    ),
    (
      LocaleKeys.showcaseFlagsNetwork,
      [('certificatePinning', AppFeatures.certificatePinning)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.screen.space(16)),
          child: Text(
            LocaleKeys.showcaseFlagsHint.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        DemoBlock(
          code: 'AppFeatures.authMode — AuthMode.…',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in AuthMode.values)
                StatusChip(
                  labelText: mode.name,
                  tone: mode == AppFeatures.authMode
                      ? StatusTone.info
                      : StatusTone.neutral,
                ),
            ],
          ),
        ),
        for (final (titleKey, flags) in _groups)
          DemoBlock(
            code: 'AppFeatures.${flags.first.$1} …',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titleKey.tr(), style: context.textTheme.headlineSmall),
                for (final (name, on) in flags)
                  Padding(
                    padding: EdgeInsets.only(top: context.screen.space(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                        StatusChip(
                          labelKey: on
                              ? LocaleKeys.showcaseFlagsOn
                              : LocaleKeys.showcaseFlagsOff,
                          tone: on ? StatusTone.success : StatusTone.neutral,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
