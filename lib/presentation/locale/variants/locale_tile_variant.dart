import 'package:flutter/material.dart';

import 'package:app_template/core/platform/locale/app_locale.dart';
import 'package:app_template/presentation/locale/locale_extension.dart';
import 'package:app_template/presentation/locale/locale_switcher_controller.dart';

/// ListTile-style locale switcher — best for settings screens.
///
/// Shows the current language name with a globe icon.
/// Tapping opens a bottom sheet to select a language.
class LocaleTileVariant extends StatelessWidget {
  const LocaleTileVariant({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.appLocale;

    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text(LocaleSwitcherController.labelFor(current)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _showPicker(context, current),
    );
  }

  void _showPicker(BuildContext context, AppLocale current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocale.values.map((locale) {
            final isSelected = locale == current;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(LocaleSwitcherController.labelFor(locale)),
              onTap: () {
                Navigator.pop(sheetContext);
                LocaleSwitcherController.switchTo(context, locale);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
