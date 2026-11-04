import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/responsive/responsive.dart';
import 'package:app_template/ui/theme/app_radius.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';

/// The line every module page opens with: what follows runs on the device
/// alone, so a reader does not mistake it for the module talking to a server.
class SimNotice extends StatelessWidget {
  const SimNotice({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: context.screen.space(16)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.statusInfoBg,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Padding(
          padding: EdgeInsets.all(context.screen.space(12)),
          child: Row(
            children: [
              Icon(Icons.science_outlined, color: colors.statusInfoFg),
              const ResponsiveGap.horizontal(8),
              Expanded(
                child: Text(
                  LocaleKeys.showcaseSimulated.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.statusInfoFg,
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
