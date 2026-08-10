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
  'pending_approval' => AuthUserStatus.pendingApproval,
  'suspended' => AuthUserStatus.suspended,
  'rejected' => AuthUserStatus.rejected,
  'disabled' => AuthUserStatus.disabled,
  _ => AuthUserStatus.active,
};

String _statusToWire(AuthUserStatus status) => switch (status) {
  AuthUserStatus.pendingApproval => 'pending_approval',
  AuthUserStatus.suspended => 'suspended',
  AuthUserStatus.rejected => 'rejected',
  AuthUserStatus.disabled => 'disabled',
  AuthUserStatus.active => 'active',
};

/// Wire shape of [AuthUser] — one field per JSON key, raw types only.
///
/// Dates stay `String` and status stays `String?` here; conversion happens in
/// [toEntity]. Keeping the raw types at the boundary means a malformed date
/// from the server fails in one known place instead of throwing wherever the
/// entity is first read.
class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    this.image,
    this.address,
    required this.isAdmin,
    this.mfaEnabled = false,
    this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String? image;
  final String? address;
  final bool isAdmin;
  final bool mfaEnabled;
  final String? status;
  final String? rejectionReason;
  final String createdAt;

  /// Reverse of [toEntity] — serializes a live [AuthUser] back to wire shape so
  /// the current user can be cached locally (see [CurrentUserRepository]).
  factory AuthUserModel.fromEntity(AuthUser user) => AuthUserModel(
    id: user.id,
    firstName: user.firstName,
    lastName: user.lastName,
    fullName: user.fullName,
    email: user.email,
    phone: user.phone,
    image: user.image,
    address: user.address,
    isAdmin: user.isAdmin,
    mfaEnabled: user.mfaEnabled,
    status: _statusToWire(user.status),
    rejectionReason: user.rejectionReason,
    createdAt: user.createdAt.toIso8601String(),
  );

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      image: json['image'] as String?,
      address: json['address'] as String?,
      // Accepts `true` and `1`: a backend that stores booleans as integers
      // sends the second, and `as bool?` would silently read it as null.
      isAdmin: (json['is_admin'] == true || json['is_admin'] == 1),
      mfaEnabled: (json['mfa_enabled'] == true || json['mfa_enabled'] == 1),
      status: json['status'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  /// Mirrors the wire shape — used only to re-serialize for local caching,
  /// never sent over the network as a request body.
  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'image': image,
    'address': address,
    'is_admin': isAdmin,
    'mfa_enabled': mfaEnabled,
    'status': status,
    'rejection_reason': rejectionReason,
    'created_at': createdAt,
  };

  AuthUser toEntity() => AuthUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: fullName,
    email: email,
    phone: phone,
    image: image,
    address: address,
    isAdmin: isAdmin,
    mfaEnabled: mfaEnabled,
    status: authUserStatusFromWire(status),
    rejectionReason: rejectionReason,
    createdAt: DateTime.tryParse(createdAt) ?? DateTime(2000),
  );
}
