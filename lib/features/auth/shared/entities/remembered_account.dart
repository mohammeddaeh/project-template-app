import 'package:equatable/equatable.dart';

/// An account this device has been told to remember — identity only.
///
/// **No credential is stored here, and none ever should be.** What this buys
/// the user is skipping the email field, nothing else: the password is still
/// typed in full on every sign-in. That is the whole security posture of the
/// feature, and it is why the entity has no field that could hold a secret.
///
/// [email] is the identity key across the whole feature. Matching is
/// case-insensitive (`m@x.com` and `M@X.com` are one account, and the server
/// lowercases addresses anyway) — see `RememberedAccountsRepository`.
class RememberedAccount extends Equatable {
  const RememberedAccount({
    required this.email,
    required this.fullName,
    required this.lastLoginAt,
    this.imageUrl,
  });

  final String email;

  /// Shown above the address on the card. Refreshed on every sign-in, so a
  /// rename on the server reaches the picker instead of freezing at whatever
  /// the name was the day it was saved.
  final String fullName;

  /// Null unless the project's `AuthUser` carries an avatar (the template's
  /// does not) — the fallback is the first letter of [fullName], drawn by
  /// `AvatarWidget`.
  final String? imageUrl;

  /// Orders the picker, most recent first, and decides who is dropped when the
  /// list is at its cap.
  final DateTime lastLoginAt;

  RememberedAccount copyWith({
    String? fullName,
    String? imageUrl,
    DateTime? lastLoginAt,
  }) => RememberedAccount(
    email: email,
    fullName: fullName ?? this.fullName,
    imageUrl: imageUrl ?? this.imageUrl,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'full_name': fullName,
    'image_url': imageUrl,
    'last_login_at': lastLoginAt.toIso8601String(),
  };

  /// Returns null for a row that cannot be trusted rather than a half-built
  /// account: this data is read at app start, and one malformed entry must not
  /// be able to empty the whole picker or crash the login screen.
  static RememberedAccount? tryFromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    if (email == null || email.isEmpty) return null;
    return RememberedAccount(
      email: email,
      fullName: json['full_name'] as String? ?? email,
      imageUrl: json['image_url'] as String?,
      lastLoginAt:
          DateTime.tryParse(json['last_login_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  List<Object?> get props => [email, fullName, imageUrl, lastLoginAt];
}
