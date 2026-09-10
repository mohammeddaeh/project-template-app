class ChangePasswordDto {
  const ChangePasswordDto({
    required this.currentPassword,
    required this.newPassword,
  });

  /// Required even though the request is authenticated.
  ///
  /// The token proves the request came from this device; it does not prove the
  /// person holding the device is the account owner. Without this field, an
  /// unlocked phone left on a desk is a permanent account takeover — the
  /// attacker changes the password and the owner is locked out of their own
  /// account.
  final String currentPassword;

  final String newPassword;

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}
