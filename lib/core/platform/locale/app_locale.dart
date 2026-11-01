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
  arabic('ar', 'العربية', 'ع'),
  english('en', 'English', 'EN');

  const AppLocale(this.code, this.nativeName, this.shortName);

  /// BCP 47 language code.
  final String code;

  /// اسمُ اللغة **بلغتها** — يُعرض كما هو بكل لغات الواجهة، فيجدها المستخدم
  /// أيّاً كانت اللغة الحالية. بيانٌ وصفيّ للّغة لا نصٌّ يُترجَم.
  final String nativeName;

  /// اختصارُه بلغته — شارةُ زرّ اللغة.
  final String shortName;

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
