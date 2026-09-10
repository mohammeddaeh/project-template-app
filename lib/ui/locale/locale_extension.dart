import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/contracts/locale_provider.dart';
import 'package:app_template/core/infra/session/locale_provider_impl.dart';
import 'package:app_template/core/platform/locale/app_locale.dart';

/// Locale-related helpers available on every [BuildContext].
///
/// ─── Usage ───────────────────────────────────────────────────────────────────
/// ```dart
/// context.appLocale              // → AppLocale.arabic / .english
/// context.isAr                   // → true / false
/// context.isRtl                  // → true / false
///
/// await context.changeLocale(AppLocale.english);  // saves + rebuilds
/// ```
extension LocaleContextExtension on BuildContext {
  /// The currently active [AppLocale].
  AppLocale get appLocale => AppLocale.fromCode(locale.languageCode);

  /// `true` when the active language is Arabic.
  bool get isAr => appLocale == AppLocale.arabic;

  /// `true` when the active language uses right-to-left layout.
  bool get isRtl => appLocale.isRtl;

  /// Changes the app locale, persists via easy_localization,
  /// and syncs [AppLocaleProvider] so HTTP interceptors stay up to date.
  Future<void> changeLocale(AppLocale newLocale) async {
    await setLocale(newLocale.locale);
    (GetIt.I<LocaleProvider>() as AppLocaleProvider).setLanguage(newLocale.code);
  }

  /// Toggles between Arabic and English.
  Future<void> toggleLocale() async {
    final next = isAr ? AppLocale.english : AppLocale.arabic;
    await changeLocale(next);
  }
}
