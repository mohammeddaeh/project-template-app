import 'package:flutter/material.dart';

import 'package:app_template/core/platform/locale/app_locale.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/locale/locale_switcher_controller.dart';

/// Text-toggle locale switcher — minimal inline style.
///
/// Renders two text buttons separated by a divider:
///   [العربية] | [English]
/// The active one is highlighted; tapping the other switches immediately.
class LocaleTextToggleVariant extends StatelessWidget {
  const LocaleTextToggleVariant({super.key});

  @override
  Widget build(BuildContext context) {
    final current  = context.appLocale;
    final primary  = Theme.of(context).colorScheme.primary;
    final disabled = Theme.of(context).colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AppLocale.values.expand((locale) {
        final isActive = locale == current;
        return [
          GestureDetector(
            onTap: isActive
                ? null
                : () => LocaleSwitcherController.switchTo(context, locale),
            child: Text(
              LocaleSwitcherController.labelFor(locale),
              style: TextStyle(
                color:      isActive ? primary : disabled,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize:   14,
              ),
            ),
          ),
          if (locale != AppLocale.values.last)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('|', style: TextStyle(color: disabled)),
            ),
        ];
      }).toList(),
    );
  }
}
