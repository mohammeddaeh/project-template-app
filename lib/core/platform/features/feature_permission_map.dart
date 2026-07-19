/// Mapping between [AppFeatures] keys and the native platform permissions.
///
/// This file is the single source of truth used by:
///   - `scripts/sync_permissions.dart` (to update manifests)
///   - Documentation (comments below list the exact entries)
///
/// ─── Android entries added per feature ───────────────────────────────────
/// camera:           android.permission.CAMERA
/// microphone:       android.permission.RECORD_AUDIO
/// location:         android.permission.ACCESS_FINE_LOCATION
///                   android.permission.ACCESS_COARSE_LOCATION
/// locationAlways:   (above) + android.permission.ACCESS_BACKGROUND_LOCATION
/// photos:           android.permission.READ_MEDIA_IMAGES        (API 33+)
///                   android.permission.READ_EXTERNAL_STORAGE     (API < 33)
/// fileStorage:      android.permission.READ_EXTERNAL_STORAGE
///                   android.permission.WRITE_EXTERNAL_STORAGE
/// contacts:         android.permission.READ_CONTACTS
/// bluetooth:        android.permission.BLUETOOTH_SCAN
///                   android.permission.BLUETOOTH_CONNECT
/// pushNotifications: android.permission.POST_NOTIFICATIONS       (API 33+)
///
/// ─── iOS keys added per feature ──────────────────────────────────────────
/// camera:           NSCameraUsageDescription
/// microphone:       NSMicrophoneUsageDescription
/// location:         NSLocationWhenInUseUsageDescription
/// locationAlways:   NSLocationWhenInUseUsageDescription
///                   NSLocationAlwaysAndWhenInUseUsageDescription
/// photos:           NSPhotoLibraryUsageDescription
/// contacts:         NSContactsUsageDescription
/// bluetooth:        NSBluetoothAlwaysUsageDescription
///
/// ─── Note ─────────────────────────────────────────────────────────────────
/// Actual manipulation is done by `scripts/sync_permissions.dart`.
/// This file is intentionally documentation-only to keep it pure Dart
/// with no script-specific I/O dependencies.
abstract final class FeaturePermissionMap {
  FeaturePermissionMap._();
}
