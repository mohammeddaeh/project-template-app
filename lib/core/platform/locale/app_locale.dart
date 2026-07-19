import 'package:flutter/widgets.dart';

/// Supported app locales.
///
/// ─── Usage ───────────────────────────────────────────────────────────────────
/// ```dart
/// // In any widget — via the BuildContext extension
/// context.isAr          // → true/false
/// context.isRtl         // → true/false
/// context.appLocale     // → AppLocale.arabic / AppLocale.english
/// await context.changeLocale(AppLocale.english);
/// ```
enum AppLocale {
  arabic('ar'),
  english('en');

  const AppLocale(this.code);

  /// BCP 47 language code.
  final String code;

  /// Whether this locale uses right-to-left text direction.
  bool get isRtl => this == arabic;

  /// Returns the [Locale] object for this app locale.
  Locale get locale => Locale(code);

  /// Resolves an [AppLocale] from a BCP 47 language code.
  /// Falls back to [arabic] for unrecognised codes.
  static AppLocale fromCode(String code) =>
      values.firstWhere((l) => l.code == code, orElse: () => arabic);

  /// All supported locales as Flutter [Locale] objects.
  static List<Locale> get supportedLocales =>
      values.map((l) => l.locale).toList();
}
