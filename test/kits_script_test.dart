import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/kits.dart';

/// The text edits behind `scripts/kit.dart` — a kit goes in with one command and
/// comes out with one, and the round trip leaves every file as it was.
void main() {
  const pubspec = '''
dependencies:
  kit_contracts:
    path: packages/kit_contracts

  get_it: ^8.0.0
''';
  const features = '''
  static const camera = false;
  static const microphone = false;
''';
  const voice = KitManifest(
    name: 'voice',
    register: 'registerVoiceKit',
    permissions: ['microphone'],
    platformPackages: ['speech_to_text'],
  );

  test('a manifest reads from kit.json', () {
    final kit = KitManifest.fromJson(
      '{"name":"scan","register":"registerScanKit",'
      '"permissions":["camera"],"platformPackages":["mobile_scanner"]}',
    );
    expect(kit.package, 'kit_scan');
    expect(kit.permissions, ['camera']);
    expect(kit.platformPackages, ['mobile_scanner']);
  });

  test('installed kits come from pubspec alone, contracts excluded', () {
    expect(installedKits(pubspec), isEmpty);
    final added = addKitDependency(pubspec, 'voice');
    expect(installedKits(added), ['voice']);
    expect(addKitDependency(added, 'voice'), added, reason: 'idempotent');
  });

  test('add then remove leaves pubspec, flags and kits file unchanged', () {
    final emptyKits = renderKitsFile([], {});

    final p = addKitDependency(pubspec, 'voice');
    final f = setFlag(features, 'microphone', true);
    final k = renderKitsFile(
      [voice],
      {
        'voice': ['microphone'],
      },
    );
    expect(flagValue(f, 'microphone'), isTrue);
    expect(k, contains("import 'package:kit_voice/kit_voice.dart';"));
    expect(k, contains('registerVoiceKit(getIt);'));
    expect(enabledFlags(k), {
      'voice': ['microphone'],
    });

    expect(removeKitDependency(p, 'voice'), pubspec);
    expect(setFlag(f, 'microphone', false), features);
    expect(renderKitsFile([], {}), emptyKits);
  });

  test('a flag the kit did not turn on is not recorded as its own', () {
    // The camera was already on (say, for MediaService): installing a kit that
    // needs it must not let removing the kit turn it off.
    final f = setFlag(features, 'camera', true);
    expect(flagValue(f, 'camera'), isTrue);
    final k = renderKitsFile([
      const KitManifest(
        name: 'scan',
        register: 'registerScanKit',
        permissions: ['camera'],
        platformPackages: [],
      ),
    ], {});
    expect(enabledFlags(k), isEmpty);
  });

  test('a missing flag fails loudly instead of being invented', () {
    expect(() => setFlag(features, 'nfc', true), throwsStateError);
  });
}
