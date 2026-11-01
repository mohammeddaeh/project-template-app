import 'package:flutter/material.dart';

import 'package:app_template/core/foundation/formatting/app_formats.dart';
import 'package:app_template/modules/showcase/presentation/sections/demo_block.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Today's date, time and a few numbers through the format catalog
/// (`app_formats.dart`) — switch the language to see both shapes.
class FormatsDemo extends StatelessWidget {
  const FormatsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final language = Localizations.localeOf(context).languageCode;
    final style = context.textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'AppDateText.format(d, format: AppDateFormats.listDate)',
          child: AppDateText.format(
            now,
            format: AppDateFormats.listDate,
            style: style,
          ),
        ),
        DemoBlock(
          code: 'AppDateFormats.detailHijri',
          child: AppDateText.format(
            now,
            format: AppDateFormats.detailHijri,
            style: style,
          ),
        ),
        DemoBlock(
          code: 'AppTimeFormats.listTime',
          child: Text(
            AppTimeFormats.listTime.apply(
              now.hour,
              now.minute,
              language: language,
              h24: MediaQuery.alwaysUse24HourFormatOf(context),
            ),
            style: style,
          ),
        ),
        DemoBlock(
          code: 'AppNumberFormats.count · .countdown',
          child: Text(
            '${AppNumberFormats.count.apply(1234567, language: language)}'
            '   ·   ${AppNumberFormats.countdown.apply(3912)}',
            style: style,
          ),
        ),
      ],
    );
  }
}
