// ignore_for_file: avoid_print
/// Reads AppFeatures and syncs AndroidManifest.xml + Info.plist.
///
/// Run from project root:
///   dart run scripts/sync_platform_permissions.dart
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
  // ⚠️ **متعمَّد فارغ — و`android.permission.CAMERA` هنا يضرّ ولا ينفع.**
  //
  // `image_picker` بأندرويد لا يفتح الكاميرا داخل العملية، بل يُرسل نيّة
  // `MediaStore.ACTION_IMAGE_CAPTURE` إلى **تطبيق الكاميرا**. والتصوير بالنيابة
  // لا يحتاج إذناً: الإذن يملكه التطبيق الذي يصوّر فعلاً.
  //
  // وإعلان `CAMERA` **يقلب القاعدة**: توثيق أندرويد صريح أن التطبيق الذي يعلن
  // الإذن ولا يمنحه المستخدمُ يصطدم بـ`SecurityException` عند استعمال هذه
  // النيّة. فالإعلان لا يفتح باباً — بل يشترط مفتاحاً لبابٍ كان مفتوحاً.
  //
  // فما اشتراه الإعلان: حوار أذونات لا وظيفة له، وعمليةُ `PermissionController`
  // تُشغَّل، وانتقال إضافي للخلفية — كلّه بالثواني التي تسبق فتح الكاميرا، وهي
  // بالضبط نافذة القتل (`readme/11_CORE.md` §3.2-م).
  //
  // **ويعود يوم يدخل المستودعَ تصويرٌ داخل العملية** — حزمة `camera` أو
  // `mobile_scanner` أو `wechat_camera_picker`. لا شيء منها اليوم بـpubspec.
  //
  // و iOS يبقى على حاله بـ`_iosPlistKeys`: `UIImagePickerController` يصوّر
  // **داخل العملية**، و`NSCameraUsageDescription` شرطٌ هناك لا خيار — غيابه
  // إسقاطٌ فوري لا حوارٌ مرفوض. الفرق بين المنصّتين حقيقي، لا سهو.
  'camera': [],
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

  print('\n✅  sync_platform_permissions done.\n');
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
  // ⚠️ يُبحث عن **نصّ** اللافتة مجرَّداً، لا عن سطرها بمسافاته البادئة.
  //
  // الثوابت `_iosStart`/`_androidStart` تحمل أربع مسافات، و`Info.plist` مُزاح
  // بـ**tabs**. فكان `indexOf` يفشل بملفٍ لافتتاه موجودتان سليمتان، فيسقط على
  // فرع «أول تشغيل» ويُلحق كتلةً **ثانية** — أي `NSCameraUsageDescription`
  // مكرّراً بملفٍ لا يحتمل تكرار المفاتيح، مع ابتلاع إزاحة `</dict>`.
  //
  // **وقع فعلاً** (2026-08-25) بأول تشغيلٍ للسكربت بعد إفراغ أذونات الكاميرا.
  // والفشل صامت تماماً: السكربت يطبع «✅ done» بالحالتين.
  final startText = startMarker.trim();
  final endText = endMarker.trim();

  var start = content.indexOf(startText);
  final end = content.indexOf(endText);

  if (start != -1 && end != -1) {
    // ابتلاع المسافة البادئة لسطر اللافتة: الكتلة الجديدة تحمل إزاحتها بنفسها،
    // وبلا هذا تبقى مسافاتٌ يتيمة قبلها تتراكم مع كل تشغيل.
    final lineStart = content.lastIndexOf('\n', start);
    if (lineStart != -1 &&
        content.substring(lineStart + 1, start).trim().isEmpty) {
      start = lineStart + 1;
    }
    return content.replaceRange(start, end + endText.length, newBlock);
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
