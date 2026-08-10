import 'package:equatable/equatable.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

class CurrentUserEntity extends Equatable {
  final AuthUser user;
  final List<String> permissionKeys;

  /// Whether this account actually holds the Super Admin role.
  ///
  /// **Not derivable from [permissionKeys]** — no permission key expresses it,
  /// and the operations gated on it (changing a role's authority level, being
  /// the protected root account) are checked by role. The server sends it so
  /// the client restates none of that rule and cannot drift from it.
  final bool isSuperAdmin;

  const CurrentUserEntity({
    required this.user,
    this.permissionKeys = const [],
    this.isSuperAdmin = false,
  });

  @override
  List<Object?> get props => [user, permissionKeys, isSuperAdmin];
}
