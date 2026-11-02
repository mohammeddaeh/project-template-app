import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/port_signals.dart';

/// The port inventory lags the template unless something makes it keep up.
///
/// A capability added to the catalog, a kit under `packages/` or a module
/// under `lib/modules/` with no signal is invisible when an old app is
/// inventoried: nothing points the port at it, and it gets written again
/// inside a feature. These tests turn that lag into a red build — and the
/// fixture proves each signal actually fires on something an old app contains.
void main() {
  final covered = {for (final s in portSignals) ...s.covers};

  test('every capability in 06_CAPABILITIES.md has a signal or a reason', () {
    final missing = [
      for (final key in _catalogKeys())
        if (!covered.contains(key) && !portSignalExemptions.containsKey(key))
          key,
    ];
    expect(
      missing,
      isEmpty,
      reason:
          'Add a PortSignal covering each to scripts/src/port_signals.dart, '
          'or an exemption with its reason.',
    );
  });

  test('every device kit has a signal pointing at scripts/kit.dart', () {
    for (final kit in _kits()) {
      final signals = portSignals.where((s) => s.covers.contains('kit:$kit'));
      expect(signals, isNotEmpty, reason: 'kit_$kit has no signal');
      for (final s in signals) {
        expect(s.target, contains('scripts/kit.dart add $kit'));
      }
    }
  });

  test('every optional module has a signal or a reason', () {
    final missing = [
      for (final m in _modules())
        if (!covered.contains('module:$m') &&
            !portSignalExemptions.containsKey('module:$m'))
          m,
    ];
    expect(missing, isEmpty);
  });

  test('no exemption is stale or contradicted by a signal', () {
    final known = {
      ..._catalogKeys(),
      for (final k in _kits()) 'kit:$k',
      for (final m in _modules()) 'module:$m',
    };
    for (final key in portSignalExemptions.keys) {
      expect(known, contains(key), reason: '$key no longer exists');
      expect(covered, isNot(contains(key)), reason: '$key is also covered');
    }
  });

  test('every signal fires on the fixture old app', () {
    final sources = {
      for (final f in Directory(
        'test/fixtures/port/old_app',
      ).listSync(recursive: true).whereType<File>())
        f.path: f.readAsStringSync(),
    };
    final fired = {for (final (s, _) in scanPortSignals(sources)) s.name};
    final silent = [
      for (final s in portSignals)
        if (!fired.contains(s.name)) s.name,
    ];
    expect(
      silent,
      isEmpty,
      reason:
          'Add a line to test/fixtures/port/old_app that the signal matches.',
    );
  });
}

/// The first symbol in the «استعمل» column of each row above «إضافة قدرة»:
/// its first segment when that is a type (`AppDateFormats.x` ⇒ `AppDateFormats`),
/// two segments for a receiver (`context.showDatePicker`), or the path itself
/// (`modules/sync/` ⇒ `modules/sync`).
Set<String> _catalogKeys() {
  final keys = <String>{};
  for (final line in File('readme/rules/06_CAPABILITIES.md').readAsLinesSync()) {
    if (line.startsWith('## إضافة قدرة')) break;
    if (!line.startsWith('| ') || line.startsWith('| الحاجة')) continue;
    final cells = line.split('|');
    if (cells.length < 4) continue;
    final token = RegExp('`([^`]+)`').firstMatch(cells[2])?.group(1);
    if (token == null) continue;
    if (token.endsWith('/')) {
      keys.add(token.substring(0, token.length - 1));
      continue;
    }
    final id = RegExp(
      r'^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?',
    ).firstMatch(token)?.group(0);
    if (id == null) continue;
    final first = id.split('.').first;
    keys.add(first[0] == first[0].toUpperCase() ? first : id);
  }
  return keys;
}

Iterable<String> _kits() => Directory('packages')
    .listSync()
    .whereType<Directory>()
    .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
    .where((n) => n.startsWith('kit_') && n != 'kit_contracts')
    .map((n) => n.substring(4));

Iterable<String> _modules() => Directory('lib/modules')
    .listSync()
    .whereType<Directory>()
    .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last);
