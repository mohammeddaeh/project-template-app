import 'app_permission.dart';
import 'app_permission_status.dart';

/// Abstract contract for runtime permission management.
///
/// Implemented by [PermissionsServiceImpl] (permission_handler).
/// Mock this interface in tests — never mock permission_handler directly.
///
/// Usage:
/// ```dart
/// final status = await _permissions.request(AppPermission.camera);
/// if (status.isGranted) { /* proceed */ }
/// if (status.needsSettings) { await _permissions.openSettings(); }
/// ```
abstract interface class PermissionsService {
  /// Returns the current status without prompting the user.
  Future<AppPermissionStatus> check(AppPermission permission);

  /// Requests the permission. Shows the system dialog if needed.
  /// Returns the resulting status after the user responds.
  Future<AppPermissionStatus> request(AppPermission permission);

  /// Requests multiple permissions at once.
  /// Returns a map of each permission to its resulting status.
  Future<Map<AppPermission, AppPermissionStatus>> requestMany(
    List<AppPermission> permissions,
  );

  /// Opens the app's system settings page.
  /// Call this when [AppPermissionStatus.needsSettings] is true and the
  /// UI has already explained why (rationale dialog is the caller's job).
  Future<void> openSettings();
}
