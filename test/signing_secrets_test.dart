import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The release key and its passwords never enter git.
///
/// A signing key committed once is in history for good — deleting it in a
/// later commit removes nothing — and whoever holds it can ship an "update"
/// to every installed copy. These paths are checked against git itself, so a
/// line removed from `.gitignore` turns this red before anything is added.
void main() {
  const secrets = [
    'key.properties',
    'android/key.properties',
    'upload.jks',
    'android/app/upload.jks',
    'android/app/release.keystore',
    'ios/certs/dist.p12',
    'ios/AuthKey_ABC123.p8',
    'ios/profiles/app.mobileprovision',
  ];

  test('every signing secret path is ignored by git', () async {
    for (final path in secrets) {
      final result = await Process.run('git', ['check-ignore', '-q', path]);
      expect(result.exitCode, 0, reason: '$path would be committed');
    }
  });

  test('no signing secret is tracked', () async {
    final result = await Process.run('git', ['ls-files']);
    final tracked = (result.stdout as String)
        .split('\n')
        .where(
          (p) =>
              p.endsWith('key.properties') ||
              RegExp(r'\.(jks|keystore|p12|p8|mobileprovision)$').hasMatch(p),
        )
        .toList();
    expect(tracked, isEmpty);
  });
}
