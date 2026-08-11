import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

/// Public on purpose: account status arrives on payloads outside this feature
/// too (any list that shows a person's state). One mapper, so a new backend
/// status value cannot be handled here and silently fall through to `active`
/// somewhere else.
///
/// Note the fallback: an **unknown** wire value becomes [AuthUserStatus.active].
/// That is the deliberate choice for a template — a new status the client has
/// not learned yet should not lock people out. If your project's statuses are
/// restrictive (a new one is more likely to mean "blocked" than "fine"), invert
/// this and default to the safest state instead.
AuthUserStatus authUserStatusFromWire(String? raw) => switch (raw) {
  'pending_verification' => AuthUserStatus.pendingVerification,
  'disabled' => AuthUserStatus.disabled,
  _ => AuthUserStatus.active,
};

String _statusToWire(AuthUserStatus status) => switch (status) {
  AuthUserStatus.pendingVerification => 'pending_verification',
  AuthUserStatus.disabled => 'disabled',
  AuthUserStatus.active => 'active',
};

/// Wire shape of [AuthUser] — one field per JSON key, raw types only.
///
/// **This is `WireAccount`**, the object `backend_template` returns as `data`
/// from `GET /api/v1/account/me` and as `data.account` from
/// `POST /api/v1/account/login`. Field for field, name for name; the mapping is
/// verified against OpenAPI examples by `test/wire_contract_test.dart`.
///
/// Dates stay `String` and status stays `String?` here; conversion happens in
/// [toEntity]. Keeping the raw types at the boundary means a malformed date
/// from the server fails in one known place instead of throwing wherever the
/// entity is first read.
class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.emailVerified = true,
    this.emailVerifiedAt,
    this.status,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String? fullName;
  final bool emailVerified;
  final String? emailVerifiedAt;
  final String? status;
  final String createdAt;

  /// Reverse of [toEntity] — serializes a live [AuthUser] back to wire shape so
  /// the current user can be cached locally (see `CurrentUserRepository`).
  factory AuthUserModel.fromEntity(AuthUser user) => AuthUserModel(
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    emailVerified: user.emailVerified,
    emailVerifiedAt: user.emailVerifiedAt?.toIso8601String(),
    status: _statusToWire(user.status),
    createdAt: user.createdAt.toIso8601String(),
  );

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      // Accepts `true` and `1`: a backend that stores booleans as integers
      // sends the second, and `as bool?` would silently read it as null.
      //
      // An ABSENT key defaults to TRUE, not false: a payload from a server with
      // verification switched off carries no such field, and reading that as
      // "unverified" would push every user into the code screen.
      emailVerified: json['email_verified'] == null
          ? true
          : (json['email_verified'] == true || json['email_verified'] == 1),
      emailVerifiedAt: json['email_verified_at'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  /// Mirrors the wire shape — used only to re-serialize for local caching,
  /// never sent over the network as a request body.
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'email_verified': emailVerified,
    'email_verified_at': emailVerifiedAt,
    'status': status,
    'created_at': createdAt,
  };

  AuthUser toEntity() => AuthUser(
    id: id,
    email: email,
    fullName: fullName,
    emailVerified: emailVerified,
    emailVerifiedAt: emailVerifiedAt != null
        ? DateTime.tryParse(emailVerifiedAt!)
        : null,
    status: authUserStatusFromWire(status),
    createdAt: DateTime.tryParse(createdAt) ?? DateTime(2000),
  );
}
