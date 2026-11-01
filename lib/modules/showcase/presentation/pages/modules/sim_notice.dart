import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
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
      padding: 16.bottomPadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.statusInfoBg,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Padding(
          padding: 12.allPadding,
          child: Row(
            children: [
              Icon(Icons.science_outlined, color: colors.statusInfoFg),
              8.widthBox,
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
