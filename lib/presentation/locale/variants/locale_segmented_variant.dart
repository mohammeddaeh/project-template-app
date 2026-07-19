import 'package:flutter/material.dart';

import 'package:app_template/core/platform/locale/app_locale.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/locale/locale_switcher_controller.dart';

/// Segmented-button locale switcher — best for onboarding or settings cards.
///
/// Renders a [SegmentedButton] with all supported locales.
class LocaleSegmentedVariant extends StatelessWidget {
  const LocaleSegmentedVariant({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.appLocale;

    return SegmentedButton<AppLocale>(
      segments: AppLocale.values
          .map(
            (locale) => ButtonSegment<AppLocale>(
              value: locale,
              label: Text(LocaleSwitcherController.labelFor(locale)),
            ),
          )
          .toList(),
      selected: {current},
      onSelectionChanged: (selected) =>
          LocaleSwitcherController.switchTo(context, selected.first),
    );
  }
}
