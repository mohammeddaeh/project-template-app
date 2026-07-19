import 'package:flutter/material.dart';

import 'package:app_template/presentation/locale/locale_switcher_controller.dart';

/// Compact icon-button locale switcher — best for AppBar actions.
///
/// Shows a globe icon with the short code of the next locale.
/// Tapping toggles immediately (AR ↔ EN).
class LocaleIconButtonVariant extends StatelessWidget {
  const LocaleIconButtonVariant({super.key});

  @override
  Widget build(BuildContext context) {
    final next = LocaleSwitcherController.nextLocale(context);

    return Tooltip(
      message: LocaleSwitcherController.labelFor(next),
      child: IconButton(
        icon: Stack(
          alignment: Alignment.bottomRight,
          children: [
            const Icon(Icons.language_rounded),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                LocaleSwitcherController.shortLabelFor(next),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        onPressed: () => LocaleSwitcherController.toggle(context),
      ),
    );
  }
}
