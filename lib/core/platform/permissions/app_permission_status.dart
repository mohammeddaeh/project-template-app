/// Unified permission result — wraps permission_handler's PermissionStatus.
///
/// Callers switch on this without importing permission_handler.
enum AppPermissionStatus {
  /// User granted the permission.
  granted,

  /// User denied the permission (can request again).
  denied,

  /// User denied permanently or selected "Don't ask again".
  /// The only recovery is [PermissionsService.openSettings].
  permanentlyDenied,

  /// OS restricts the permission (parental controls, MDM, etc.).
  restricted,

  /// iOS only: user granted limited access (e.g. selected photos only).
  limited;

  bool get isGranted => this == granted || this == limited;
  bool get isDenied => this == denied || this == restricted;
  bool get isPermanentlyDenied => this == permanentlyDenied;
  bool get needsSettings => this == permanentlyDenied || this == restricted;
}
