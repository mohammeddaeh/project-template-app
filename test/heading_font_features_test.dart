import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/infra/config/app_fonts.dart';
import 'package:app_template/presentation/theme/app_theme.dart';

/// Headings must carry the font's stylistic set, and only headings.
///
/// ## Why this is pinned rather than reviewed
///
/// A text shaper **silently ignores** an OpenType tag the font does not define.
/// There is no exception, no log, and no visual error state — the text simply
/// renders in its default forms. So every way this can break produces the same
/// output as "working, but this font has no alternates":
///
/// - the tag is misspelled (`ss1`, `SS01`)
/// - the map key stops matching the family name
/// - a new heading style is added and nobody passes the features to it
/// - `sync_fonts.dart` regenerates `AppFonts` and swallows the declaration
///
/// None of those fail a build, and none of them look wrong on a screen you have
/// not memorised. Only an assertion on the resolved [TextStyle] catches them.
///
/// ## Why the negative cases are half the test
///
/// Asserting only that headings carry the feature would still pass if something
/// applied it to *everything* — which is the other way to get this wrong, and
/// the more damaging one: display alternates down a list of 14px card titles.
/// And the `sans` group proves the map is actually consulted; without it, a
/// hardcoded `[FontFeature('ss01')]` on every style would satisfy the rest.
void main() {
  const ss01 = FontFeature('ss01');

  bool carries(TextStyle? style) => style?.fontFeatures?.contains(ss01) ?? false;

  // Arabic locale so both options resolve to their Arabic family.
  final qomra = AppThemeData.light(
    const Locale('ar'),
    AppFonts.byKey('qomra'),
  );
  final sans = AppThemeData.light(const Locale('ar'), AppFonts.byKey('sans'));

  group('Qomra — headings at 18px and above', () {
    final headings = <String, TextStyle?>{
      'displayLarge (24)': qomra.textTheme.displayLarge,
      'displayMedium (18)': qomra.textTheme.displayMedium,
      'headlineLarge (26)': qomra.textTheme.headlineLarge,
      'headlineMedium (20)': qomra.textTheme.headlineMedium,
      // The two hand-written title styles that live outside `_textTheme` — the
      // ones that were missed the first time, and the AppBar is the heading
      // this app shows most often.
      'appBarTheme.titleTextStyle (18)': qomra.appBarTheme.titleTextStyle,
      'dialogTheme.titleTextStyle (20)': qomra.dialogTheme.titleTextStyle,
    };

    headings.forEach((name, style) {
      test('$name carries ss01', () {
        expect(
          carries(style),
          isTrue,
          reason:
              '$name is a heading at 18px or above and must request the font\'s '
              'stylistic set. Nothing will fail if this regresses — the text '
              'just renders in its plain forms, and the screen looks subtly '
              'unlike every other heading with no error to trace.',
        );
      });
    });
  });

  group('Qomra — everything below the threshold does not', () {
    final plain = <String, TextStyle?>{
      'displaySmall (16)': qomra.textTheme.displaySmall,
      'headlineSmall (14)': qomra.textTheme.headlineSmall,
      'titleLarge (16)': qomra.textTheme.titleLarge,
      'bodyMedium (14)': qomra.textTheme.bodyMedium,
      'labelLarge (14)': qomra.textTheme.labelLarge,
      'dialogTheme.contentTextStyle (14)': qomra.dialogTheme.contentTextStyle,
    };

    plain.forEach((name, style) {
      test('$name stays plain', () {
        expect(
          carries(style),
          isFalse,
          reason:
              '$name is body-sized text. `headlineSmall` in particular is this '
              'app\'s card title, repeated down a whole list — display '
              'alternates there read as noise and their wider advances push '
              'against rows that already ellipsize.',
        );
      });
    });
  });

  group('a font that declares no stylistic set gets none', () {
    test('NotoSansArabic headings request nothing', () {
      final everyStyle = <TextStyle?>[
        sans.textTheme.displayLarge,
        sans.textTheme.displayMedium,
        sans.textTheme.headlineLarge,
        sans.textTheme.headlineMedium,
        sans.appBarTheme.titleTextStyle,
        sans.dialogTheme.titleTextStyle,
      ];

      expect(
        everyStyle.any(carries),
        isFalse,
        reason:
            'The features must come from AppFonts.headingFeaturesFor(family), '
            'not from a constant pasted into the theme. If this ever passes '
            'ss01 to a family that has no entry, the lookup has been bypassed '
            'and the two tests above prove nothing.',
      );
    });
  });
}
