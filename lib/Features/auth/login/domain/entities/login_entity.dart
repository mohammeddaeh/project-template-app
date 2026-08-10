import 'package:equatable/equatable.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

class LoginEntity extends Equatable {
  final String token;
  final AuthUser user;
  final List<String> permissionKeys;

  /// See `CurrentUserEntity.isSuperAdmin` — carried on the login response too
  /// so the session is fully known from the moment it starts, rather than one
  /// background refresh later.
  final bool isSuperAdmin;

  const LoginEntity({
    required this.token,
    required this.user,
    this.permissionKeys = const [],
    this.isSuperAdmin = false,
  });

  @override
  List<Object?> get props => [token, user, permissionKeys, isSuperAdmin];
}
