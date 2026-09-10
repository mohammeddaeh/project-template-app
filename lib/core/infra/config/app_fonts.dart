import 'dart:ui' show FontFeature;

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

  // ── OpenType heading features — NOT generated, keep below the marker ───────
  //
  // Deliberately a map keyed by family name rather than a field on
  // [AppFontOption]: `sync_fonts.dart` rewrites everything between the BEGIN/END
  // markers above and emits only the five constructor arguments it knows about.
  // A sixth argument added up there survives until the next time anyone runs the
  // script, then vanishes — and the headings quietly revert to their plain forms
  // with nothing failing and no diff anyone reads. Down here the script cannot
  // reach it.

  /// Stylistic sets applied to **large headings only**, per font family.
  ///
  /// `itfQomraArabic` ships four stylistic sets (`ss01`–`ss04`, verified in the
  /// three bundled .ttf files alongside `salt`, `dlig` and `calt`). `ss01` is
  /// the designer's alternate/extended letterforms — the shapes that make a
  /// title read as a title rather than as large body text.
  ///
  /// **Headings only, and only at 18px and above.** These alternates are drawn
  /// for display sizes: at the 14px of a card title they cost legibility, and
  /// their wider advance widths eat into rows that already ellipsize.
  ///
  /// A family with no entry gets `const []` — no feature is requested, which is
  /// also what happens for `NotoSansArabic`/`NotoSans`. Nothing here is a
  /// fallback: an unsupported tag is silently ignored by the shaper, so a wrong
  /// entry would look like nothing at all rather than like an error. That is
  /// why `test/heading_font_features_test.dart` asserts the resolved styles.
  ///
  /// To try another set, change the tag: `FontFeature('ss02')`.
  ///
  /// Written as `FontFeature('ss01')` and not `FontFeature.stylisticSet(1)`:
  /// the two are identical in effect, but `stylisticSet` is a **factory**, so it
  /// is not a constant and this map could not be `const` with it.
  static const Map<String, List<FontFeature>> _headingFeatures =
      <String, List<FontFeature>>{
        'itfQomraArabic': <FontFeature>[FontFeature('ss01')],
      };

  /// The heading features for [family], or empty when the family declares none.
  static List<FontFeature> headingFeaturesFor(String family) =>
      _headingFeatures[family] ?? const <FontFeature>[];

  // ── Optical centre correction — NOT generated, keep below the marker ───────
  //
  // Same reason as [_headingFeatures] above: `sync_fonts.dart` rewrites
  // everything between the BEGIN/END markers and emits only the five
  // constructor arguments it knows about. A sixth field on [AppFontOption]
  // survives until the next run of the script, then vanishes silently.

  /// How far **digit and Latin** ink must move **down**, as a fraction of
  /// `fontSize`, to sit at the optical centre of its own line box.
  ///
  /// An Arabic font reserves a tall ascent for tashkeel and a short descent.
  /// `itfQomraArabic` measures `ascent 1851 / descent −998` over
  /// `unitsPerEm 2048`: a line box of `1.391em` whose baseline sits `0.904em`
  /// from the top — **top-heavy by design**. Arabic ink fills that box almost
  /// exactly (`ع م ق` reach `yMin −632`), so Arabic is off-centre by only
  /// `1.25%` and needs no correction. Digits and Latin have no descenders —
  /// their ink spans `yMin −26 … yMax 1459` — so it all sits in the upper part
  /// and reads visibly high inside any centred box.
  ///
  ///     ink centre from top = (ascent − (yMin + yMax) / 2) / unitsPerEm
  ///                         = (1851 − 716.5) / 2048          = 0.5540em
  ///     box centre          = (ascent − descent) / 2 / unitsPerEm
  ///                         = 2849 / 2 / 2048                = 0.6956em
  ///     correction          = 0.6956 − 0.5540                = 0.1416em
  ///
  /// **No `TextStyle` property fixes this.** `height`, `leadingDistribution`
  /// and `StrutStyle` all distribute *leading* around the font's ascent:descent
  /// ratio without changing that ratio, so the offset above is invariant under
  /// every one of them. The only lever is a paint-time shift — which is what
  /// `GlyphCenter` in `ui/widgets/misc/glyph_center.dart` applies, and the sole
  /// consumer of this map.
  ///
  /// Rebalancing the `.ttf` metrics instead was measured and rejected: it moves
  /// the error onto Arabic (`1.25%` → `15.4%` low in every centred button and
  /// chip), or grows the line box by 20% app-wide if the descent is preserved.
  ///
  /// A family with no entry gets `0` — no shift, which is the correct default
  /// for a metrically balanced family such as `NotoSans`.
  static const Map<String, double> _opticalCenterCorrection = <String, double>{
    'itfQomraArabic': 0.1416,
  };

  /// The optical centre correction for [family], or `0` when it needs none.
  static double opticalCenterCorrectionFor(String family) =>
      _opticalCenterCorrection[family] ?? 0;
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
