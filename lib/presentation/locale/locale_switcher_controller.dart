import 'package:flutter/widgets.dart';

import 'package:app_template/core/platform/locale/app_locale.dart';
import 'locale_extension.dart';

/// Shared controller used by all [LocaleSwitcher] variants.
///
/// Centralises all locale-switching logic so variants contain only UI code.
class LocaleSwitcherController {
  const LocaleSwitcherController._();

  /// Switches to [target] and rebuilds the widget tree.
  static Future<void> switchTo(BuildContext context, AppLocale target) =>
      context.changeLocale(target);

  /// Toggles between Arabic and English.
  static Future<void> toggle(BuildContext context) => context.toggleLocale();

  /// The locale that would be activated next (used to label the toggle button).
  static AppLocale nextLocale(BuildContext context) =>
      context.isAr ? AppLocale.english : AppLocale.arabic;

  /// Display label for [locale].
  static String labelFor(AppLocale locale) => switch (locale) {
        AppLocale.arabic  => 'العربية',
        AppLocale.english => 'English',
      };

  /// Short code label (used in segmented / icon variants).
  static String shortLabelFor(AppLocale locale) => switch (locale) {
        AppLocale.arabic  => 'ع',
        AppLocale.english => 'EN',
      };
}
