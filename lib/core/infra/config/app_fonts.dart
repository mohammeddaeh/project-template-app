/// Font catalog — single source of truth for available fonts.
///
/// To add a new font family:
///   1. Put .ttf files in  assets/fonts/FamilyName>/
///   2. Register the family in pubspec.yaml under `flutter → fonts`
///   3. Add an [AppFontOption] entry to [AppFonts.available] below
///   4. Hot-restart to see the result immediately
abstract final class AppFonts {
  // ── BEGIN GENERATED — dart run scripts/sync_fonts.dart ───────────────────
  static const String defaultKey = 'qomra';

  static const List<AppFontOption> available = [
    AppFontOption(
      key: 'qomra',
      arabicLabel: 'قمرة',
      latinLabel: 'Qomra.',
      arabicFamily: 'itfQomraArabic',
      latinFamily: 'itfQomraArabic', // same as Arabic
    ),
    AppFontOption(
      key: 'sans',
      arabicLabel: 'سان',
      latinLabel: 'Sans',
      arabicFamily: 'NotoSansArabic',
      latinFamily: 'NotoSans',
    ),
  ];
  // ── END GENERATED ─────────────────────────────────────────────────────────

  static AppFontOption byKey(String key) =>
      available.firstWhere((f) => f.key == key, orElse: () => available.first);
}

/// A single font option: two families (one for AR, one for Latin) + display labels.
class AppFontOption {
  const AppFontOption({
    required this.key,
    required this.arabicLabel,
    required this.latinLabel,
    required this.arabicFamily,
    required this.latinFamily,
  });

  /// Unique identifier stored in SharedPreferences.
  final String key;

  /// Label shown when locale == 'ar'.
  final String arabicLabel;

  /// Label shown when locale != 'ar'.
  final String latinLabel;

  /// Font family used for Arabic (`locale.languageCode == 'ar'`).
  final String arabicFamily;

  /// Font family used for all other locales.
  final String latinFamily;

  String labelFor(String languageCode) =>
      languageCode == 'ar' ? arabicLabel : latinLabel;

  String familyFor(String languageCode) =>
      languageCode == 'ar' ? arabicFamily : latinFamily;

  @override
  bool operator ==(Object other) => other is AppFontOption && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
