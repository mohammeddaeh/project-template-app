import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/pages/devices/kit_notice.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// `kit_system` — a shortcut on the launcher icon that opens a route, and the
/// store's rating sheet.
class SystemDemo extends StatefulWidget {
  const SystemDemo({super.key});

  @override
  State<SystemDemo> createState() => _SystemDemoState();
}

class _SystemDemoState extends State<SystemDemo> {
  bool? _storeAvailable;

  bool get _installed => getIt.isRegistered<AppShortcuts>();

  @override
  void initState() {
    super.initState();
    if (_installed) {
      getIt<AppReview>().isAvailable().then((a) {
        if (mounted) setState(() => _storeAvailable = a);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textMuted,
    );
    final available = _storeAvailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitNotice(kit: 'system', installed: _installed),
        DemoBlock(
          code:
              'getIt<AppShortcuts>().setShortcuts([\n'
              "  AppShortcut(path: '/welcome', title: …),\n"
              '])',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: LocaleKeys.showcaseShortcutAdd.tr(),
                leadingIcon: Icons.app_shortcut,
                isEnabled: _installed,
                onTap: () => getIt<AppShortcuts>().setShortcuts([
                  AppShortcut(
                    path: '/welcome',
                    title: LocaleKeys.showcaseShortcutTitle.tr(),
                  ),
                ]),
              ),
              8.heightBox,
              AppButton(
                text: LocaleKeys.showcaseShortcutClear.tr(),
                variant: AppButtonVariant.outlined,
                isEnabled: _installed,
                onTap: () => getIt<AppShortcuts>().setShortcuts(const []),
              ),
              8.heightBox,
              Text(LocaleKeys.showcaseShortcutHint.tr(), style: muted),
            ],
          ),
        ),
        DemoBlock(
          code:
              'getIt<AppReview>().request();      // the store decides\n'
              'getIt<AppReview>().openStore();    // always opens',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (available != null) ...[
                Text(
                  (available
                          ? LocaleKeys.showcaseReviewAvailable
                          : LocaleKeys.showcaseReviewUnavailable)
                      .tr(),
                  style: muted,
                ),
                8.heightBox,
              ],
              AppButton(
                text: LocaleKeys.showcaseReviewRequest.tr(),
                variant: AppButtonVariant.tonal,
                leadingIcon: Icons.star_rate_outlined,
                isEnabled: _installed,
                onTap: () => getIt<AppReview>().request(),
              ),
              8.heightBox,
              AppButton(
                text: LocaleKeys.showcaseReviewStore.tr(),
                variant: AppButtonVariant.outlined,
                leadingIcon: Icons.storefront_outlined,
                isEnabled: _installed,
                onTap: () => getIt<AppReview>().openStore(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
