// ignore_for_file: avoid_print
/// Reads AppFeatures and syncs AndroidManifest.xml + Info.plist.
///
/// Run from project root:
///   dart run scripts/sync_permissions.dart
///
/// All managed entries are wrapped in sync markers so the script
/// can safely add/remove them on every run without touching manual entries.
library;

import 'dart:io';

// ── Managed block markers ────────────────────────────────────────────────────
const _androidStart = '    <!-- SYNC:PERMISSIONS:START -->';
const _androidEnd   = '    <!-- SYNC:PERMISSIONS:END -->';
const _iosStart     = '    <!-- SYNC:PERMISSIONS:START -->';
const _iosEnd       = '    <!-- SYNC:PERMISSIONS:END -->';

// ── Android permissions per feature ─────────────────────────────────────────
const _androidPermissions = <String, List<String>>{
  'camera': [
    'android.permission.CAMERA',
  ],
  'microphone': [
    'android.permission.RECORD_AUDIO',
  ],
  'location': [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
  ],
  'locationAlways': [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_BACKGROUND_LOCATION',
  ],
  'photos': [
    'android.permission.READ_MEDIA_IMAGES',
    'android.permission.READ_EXTERNAL_STORAGE',
  ],
  'fileStorage': [
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE',
  ],
  'contacts': [
    'android.permission.READ_CONTACTS',
  ],
  'bluetooth': [
    'android.permission.BLUETOOTH_SCAN',
    'android.permission.BLUETOOTH_CONNECT',
  ],
  'pushNotifications': [
    'android.permission.POST_NOTIFICATIONS',
  ],
  'localNotifications': [
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.USE_EXACT_ALARM',
    'android.permission.RECEIVE_BOOT_COMPLETED',
  ],
};

// ── iOS plist keys per feature ───────────────────────────────────────────────
const _iosPlistKeys = <String, Map<String, String>>{
  'camera': {
    'NSCameraUsageDescription':
        'This app uses the camera to capture photos and videos.',
  },
  'microphone': {
    'NSMicrophoneUsageDescription':
        'This app uses the microphone for audio recording.',
  },
  'location': {
    'NSLocationWhenInUseUsageDescription':
        'This app uses your location to provide location-based services.',
  },
  'locationAlways': {
    'NSLocationWhenInUseUsageDescription':
        'This app uses your location to provide location-based services.',
    'NSLocationAlwaysAndWhenInUseUsageDescription':
        'This app uses your location in the background.',
  },
  'photos': {
    'NSPhotoLibraryUsageDescription':
        'This app accesses your photo library to let you select images.',
  },
  'fileStorage': {
    'NSPhotoLibraryAddUsageDescription':
        'This app saves files to your photo library.',
  },
  'contacts': {
    'NSContactsUsageDescription':
        'This app accesses your contacts.',
  },
  'bluetooth': {
    'NSBluetoothAlwaysUsageDescription':
        'This app uses Bluetooth to connect to nearby devices.',
  },
  'localNotifications': {
    'UIBackgroundModes': 'fetch',
  },
};

// ────────────────────────────────────────────────────────────────────────────

void main() {
  final featuresFile = File(
    'lib/core/platform/features/app_features.dart',
  );

  if (!featuresFile.existsSync()) {
    _error('app_features.dart not found at ${featuresFile.path}');
    exit(1);
  }

  final enabled = _parseFeatures(featuresFile.readAsStringSync());
  print('\n📋 Enabled features: ${enabled.isEmpty ? "none" : enabled.join(", ")}');

  _syncAndroid(enabled);
  _syncIos(enabled);

  print('\n✅  sync_permissions done.\n');
}

// ── Parse ────────────────────────────────────────────────────────────────────

List<String> _parseFeatures(String source) {
  final enabled = <String>[];
  final pattern = RegExp(r'static const (\w+)\s*=\s*(true|false)');
  for (final match in pattern.allMatches(source)) {
    final name  = match.group(1)!;
    final value = match.group(2)!;
    if (value == 'true') enabled.add(name);
  }
  return enabled;
}

// ── Android ──────────────────────────────────────────────────────────────────

void _syncAndroid(List<String> enabled) {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    _warn('AndroidManifest.xml not found — skipping Android sync.');
    return;
  }

  final permissions = <String>{};
  for (final feature in enabled) {
    permissions.addAll(_androidPermissions[feature] ?? []);
  }

  final lines = permissions.map(
    (p) => '    <uses-permission android:name="$p"/>',
  );

  final block = [
    _androidStart,
    ...lines,
    _androidEnd,
  ].join('\n');

  var content = manifest.readAsStringSync();
  content = _replaceBlock(content, _androidStart, _androidEnd, block);
  manifest.writeAsStringSync(content);

  print('🤖 Android: ${permissions.length} permission(s) written to AndroidManifest.xml');
}

// ── iOS ──────────────────────────────────────────────────────────────────────

void _syncIos(List<String> enabled) {
  final plist = File('ios/Runner/Info.plist');
  if (!plist.existsSync()) {
    _warn('Info.plist not found — skipping iOS sync.');
    return;
  }

  final keys = <String, String>{};
  for (final feature in enabled) {
    keys.addAll(_iosPlistKeys[feature] ?? {});
  }

  final lines = keys.entries.expand(
    (e) => [
      '    <key>${e.key}</key>',
      '    <string>${e.value}</string>',
    ],
  );

  final block = [
    _iosStart,
    ...lines,
    _iosEnd,
  ].join('\n');

  var content = plist.readAsStringSync();
  content = _replaceBlock(content, _iosStart, _iosEnd, block);
  plist.writeAsStringSync(content);

  print('🍎 iOS: ${keys.length} plist key(s) written to Info.plist');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Replaces the managed block between [startMarker] and [endMarker].
/// If no block exists yet, inserts before `</manifest>` (Android)
/// or before `</dict>` (iOS).
String _replaceBlock(
  String content,
  String startMarker,
  String endMarker,
  String newBlock,
) {
  final start = content.indexOf(startMarker);
  final end   = content.indexOf(endMarker);

  if (start != -1 && end != -1) {
    return content.replaceRange(start, end + endMarker.length, newBlock);
  }

  // First run — insert before closing tag
  for (final closing in ['</manifest>', '</dict>']) {
    final idx = content.lastIndexOf(closing);
    if (idx != -1) {
      return content.replaceRange(idx, idx, '$newBlock\n');
    }
  }

  _warn('Could not find insertion point — file not modified.');
  return content;
}

void _warn(String msg)  => print('⚠️  $msg');
void _error(String msg) => print('❌  $msg');
