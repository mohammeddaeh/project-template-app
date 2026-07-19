import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app_template/core/platform/features/app_features.dart';
import 'app_permission.dart';
import 'app_permission_status.dart';
import 'permissions_service.dart';

@LazySingleton(as: PermissionsService)
class PermissionsServiceImpl implements PermissionsService {
  @override
  Future<AppPermissionStatus> check(AppPermission permission) async {
    if (!AppFeatures.isEnabled(permission)) return AppPermissionStatus.denied;
    final status = await _toNative(permission).status;
    return _fromNative(status);
  }

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    if (!AppFeatures.isEnabled(permission)) return AppPermissionStatus.denied;
    final status = await _toNative(permission).request();
    return _fromNative(status);
  }

  @override
  Future<Map<AppPermission, AppPermissionStatus>> requestMany(
    List<AppPermission> permissions,
  ) async {
    final enabled = permissions.where(AppFeatures.isEnabled).toList();
    final disabled = permissions.where((p) => !AppFeatures.isEnabled(p));

    final native = enabled.map(_toNative).toList();
    final results = await native.request();

    return {
      for (final entry in results.entries)
        _fromNativePermission(entry.key): _fromNative(entry.value),
      for (final p in disabled) p: AppPermissionStatus.denied,
    };
  }

  @override
  Future<void> openSettings() => openAppSettings();

  // ── Mapping helpers ────────────────────────────────────────────────────────

  Permission _toNative(AppPermission p) => switch (p) {
        AppPermission.camera => Permission.camera,
        AppPermission.microphone => Permission.microphone,
        AppPermission.location => Permission.location,
        AppPermission.locationAlways => Permission.locationAlways,
        AppPermission.photos => Permission.photos,
        AppPermission.storage => Permission.storage,
        AppPermission.notifications => Permission.notification,
        AppPermission.contacts => Permission.contacts,
        AppPermission.bluetooth => Permission.bluetooth,
      };

  AppPermission _fromNativePermission(Permission p) => switch (p) {
        Permission.camera => AppPermission.camera,
        Permission.microphone => AppPermission.microphone,
        Permission.location => AppPermission.location,
        Permission.locationAlways => AppPermission.locationAlways,
        Permission.photos => AppPermission.photos,
        Permission.storage => AppPermission.storage,
        Permission.notification => AppPermission.notifications,
        Permission.contacts => AppPermission.contacts,
        Permission.bluetooth => AppPermission.bluetooth,
        _ => AppPermission.camera, // fallback — never reached for known types
      };

  AppPermissionStatus _fromNative(PermissionStatus s) => switch (s) {
        PermissionStatus.granted => AppPermissionStatus.granted,
        PermissionStatus.denied => AppPermissionStatus.denied,
        PermissionStatus.permanentlyDenied =>
          AppPermissionStatus.permanentlyDenied,
        PermissionStatus.restricted => AppPermissionStatus.restricted,
        PermissionStatus.limited => AppPermissionStatus.limited,
        _ => AppPermissionStatus.denied,
      };
}
