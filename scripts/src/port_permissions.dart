/// أذونات المنصّة بالتطبيق القديم ⇐ العلَم الذي يُشعلها بالقالب.
///
/// إذنٌ ناقص لا يُفشل بناءً ولا اختباراً: الطلب يُرفض على الجهاز، أو يُغلق iOS
/// التطبيق لحظةَ يسأل بلا نصّ `NS…UsageDescription`. فيُجرد من
/// `AndroidManifest.xml` و`Info.plist`، ويُشعَل العلَم ثم
/// `dart run scripts/sync_platform_permissions.dart` يكتب الأذونات.
library;

/// الإذن ⇐ علَم `AppFeatures` (`null` = لا علَم: يُعلَن دائماً أو لا مقابل له).
const portPermissionFlags = <String, String?>{
  // Android — `android.permission.<X>`
  'CAMERA': 'camera',
  'RECORD_AUDIO': 'microphone',
  'ACCESS_FINE_LOCATION': 'location',
  'ACCESS_COARSE_LOCATION': 'location',
  'ACCESS_BACKGROUND_LOCATION': 'locationAlways',
  'READ_MEDIA_IMAGES': 'photos',
  'READ_MEDIA_VIDEO': 'photos',
  'READ_EXTERNAL_STORAGE': 'photos',
  'WRITE_EXTERNAL_STORAGE': 'fileStorage',
  'MANAGE_EXTERNAL_STORAGE': 'fileStorage',
  'READ_CONTACTS': 'contacts',
  'WRITE_CONTACTS': 'contacts',
  'BLUETOOTH': 'bluetooth',
  'BLUETOOTH_ADMIN': 'bluetooth',
  'BLUETOOTH_CONNECT': 'bluetooth',
  'BLUETOOTH_SCAN': 'bluetooth',
  'POST_NOTIFICATIONS': 'pushNotifications · localNotifications',
  'SCHEDULE_EXACT_ALARM': 'localNotifications',
  'USE_BIOMETRIC': 'biometrics',
  'USE_FINGERPRINT': 'biometrics',
  'VIBRATE': 'haptics',
  'INTERNET': null,
  'ACCESS_NETWORK_STATE': null,
  // iOS — `Info.plist`
  'NSCameraUsageDescription': 'camera',
  'NSMicrophoneUsageDescription': 'microphone',
  'NSSpeechRecognitionUsageDescription': 'speechRecognition',
  'NSLocationWhenInUseUsageDescription': 'location',
  'NSLocationAlwaysAndWhenInUseUsageDescription': 'locationAlways',
  'NSLocationAlwaysUsageDescription': 'locationAlways',
  'NSPhotoLibraryUsageDescription': 'photos',
  'NSPhotoLibraryAddUsageDescription': 'photos',
  'NSContactsUsageDescription': 'contacts',
  'NSBluetoothAlwaysUsageDescription': 'bluetooth',
  'NSFaceIDUsageDescription': 'biometrics',
};

class PortPermission {
  const PortPermission(this.name, this.flag, this.source);

  final String name;

  /// `null` لإذنٍ بلا علَم — يُراجَع بالعين.
  final String? flag;
  final String source;

  bool get known => portPermissionFlags.containsKey(name);
}

final _android = RegExp(
  r'''uses-permission(?:-sdk-\d+)?\s+android:name=["']android\.permission\.(\w+)["']''',
);
final _ios = RegExp(r'<key>(NS\w+UsageDescription)</key>');

/// الأذونات المُعلَنة، مرتّبةً بالاسم، بلا تكرار.
List<PortPermission> readPermissions(Map<String, String> sources) {
  final found = <String, PortPermission>{};
  for (final e in sources.entries) {
    final re = e.key.endsWith('AndroidManifest.xml')
        ? _android
        : e.key.endsWith('Info.plist')
        ? _ios
        : null;
    if (re == null) continue;
    for (final m in re.allMatches(e.value)) {
      final name = m[1]!;
      found.putIfAbsent(
        name,
        () => PortPermission(name, portPermissionFlags[name], e.key),
      );
    }
  }
  return found.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}
