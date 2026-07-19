/// All permissions the app may ever request.
///
/// Add a new value here when your feature needs a new permission.
/// The mapping to the native [Permission] is handled inside
/// [PermissionsServiceImpl] — callers never import permission_handler.
enum AppPermission {
  camera,
  microphone,
  location,
  locationAlways,
  photos,
  storage,
  notifications,
  contacts,
  bluetooth,
}
