import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/palette_sync.dart';

void main() {
  const locales = {'ar', 'en'};
  Map<String, dynamic> file(Map<String, dynamic> colors) => {
    'name': {'ar': 'اسم', 'en': 'Name'},
    'colors': colors,
  };

  group('parsePalette', () {
    test('reads the id from the file name, colors as ARGB in file order', () {
      final p = parsePalette(
        'deep_ocean',
        file({'primaryMain': '#1e6fd9', 'shadow': '#33000000'}),
        locales,
      );
      expect(p.nameKey, 'themePresetDeepOcean');
      expect(p.dartName, 'deepOcean');
      expect(p.colors, {'primaryMain': 0xFF1E6FD9, 'shadow': 0x33000000});
    });

    test('a name missing for any translation file fails', () {
      expect(
        () => parsePalette('ocean', {
          'name': {'ar': 'المحيط'},
          'colors': {'primaryMain': '#000000'},
        }, locales),
        throwsA(isA<PaletteError>()),
      );
    });

    test('a color not in #RRGGBB or #AARRGGBB fails', () {
      for (final bad in ['1E6FD9', '#1E6FD', 'blue', 12]) {
        expect(
          () => parsePalette('ocean', file({'primaryMain': bad}), locales),
          throwsA(isA<PaletteError>()),
          reason: '$bad',
        );
      }
    });

    test('an id that is not snake_case fails', () {
      for (final bad in ['Ocean', 'deep-ocean', '1ocean']) {
        expect(
          () => parsePalette(bad, file({'primaryMain': '#000000'}), locales),
          throwsA(isA<PaletteError>()),
          reason: bad,
        );
      }
    });
  });

  group('orderAndCheck', () {
    PaletteFile palette(String id, Map<String, String> colors) =>
        parsePalette(id, file(colors), locales);

    test('standard comes first, then the rest by id', () {
      final ordered = orderAndCheck([
        palette('ocean', {'a': '#000000'}),
        palette('standard', {'a': '#000000'}),
        palette('forest', {'a': '#000000'}),
      ]);
      expect(ordered.map((p) => p.id), ['standard', 'forest', 'ocean']);
    });

    test('no standard.json fails', () {
      expect(
        () => orderAndCheck([
          palette('ocean', {'a': '#000000'}),
        ]),
        throwsA(isA<PaletteError>()),
      );
    });

    test('a palette with a missing or an extra key fails', () {
      final standard = palette('standard', {'a': '#000000', 'b': '#000000'});
      for (final colors in [
        {'a': '#000000'},
        {'a': '#000000', 'b': '#000000', 'c': '#000000'},
      ]) {
        expect(
          () => orderAndCheck([standard, palette('ocean', colors)]),
          throwsA(isA<PaletteError>()),
          reason: '$colors',
        );
      }
    });
  });

  test('theme names follow the section title; a removed one is dropped', () {
    final after = applyThemeNames(
      {
        'a': '1',
        'themePreset': 'App colors',
        'themePresetRemoved': 'Gone',
        'z': '2',
      },
      [
        parsePalette('standard', file({'a': '#000000'}), locales),
      ],
      'en',
    );
    expect(after.keys.toList(), [
      'a',
      'themePreset',
      'themePresetStandard',
      'z',
    ]);
    expect(after['themePresetStandard'], 'Name');
  });
}
