import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// Opens a device-kit page when the kit is absent: its widgets draw nothing,
/// and without this line the page would read as broken rather than empty.
class KitNotice extends StatelessWidget {
  const KitNotice({super.key, required this.kit, required this.installed});

  final String kit;
  final bool installed;

  @override
  Widget build(BuildContext context) {
    if (installed) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: context.screen.space(16)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.statusWarningBg,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Padding(
          padding: EdgeInsets.all(context.screen.space(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.showcaseKitMissing.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.statusWarningFg,
                ),
              ),
              const ResponsiveGap(4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  'dart run scripts/kit.dart add $kit',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.statusWarningFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
