import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/port_permissions.dart';

/// A permission the port forgets fails nowhere but on a device: Android refuses
/// the request, and iOS kills the app the moment it asks without a usage
/// string. These keep the old app's permissions mapped to the flags that
/// declare them here.
void main() {
  test('Android and iOS permissions map to their AppFeatures flags', () {
    final found = readPermissions({
      'android/app/src/main/AndroidManifest.xml': '''
        <uses-permission android:name="android.permission.CAMERA" />
        <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
        <uses-permission android:name="android.permission.CAMERA" />
        <uses-permission android:name="android.permission.READ_CALENDAR" />''',
      'ios/App/App/Info.plist': '''
        <key>NSMicrophoneUsageDescription</key><string>…</string>''',
      'src/app.ts':
          '<uses-permission android:name="android.permission.CAMERA"/>',
    });
    expect(
      {for (final p in found) p.name: p.flag},
      {
        'ACCESS_FINE_LOCATION': 'location',
        'CAMERA': 'camera',
        'NSMicrophoneUsageDescription': 'microphone',
        'READ_CALENDAR': null,
      },
    );
    expect(found.firstWhere((p) => p.name == 'READ_CALENDAR').known, isFalse);
  });

  test('every flag the mapping names exists in AppFeatures', () {
    final features = File(
      'lib/core/platform/features/app_features.dart',
    ).readAsStringSync();
    final flags = {
      for (final f in portPermissionFlags.values.whereType<String>())
        ...f.split(' · '),
    };
    for (final flag in flags) {
      expect(features, contains('static const $flag = '), reason: flag);
    }
  });
}
