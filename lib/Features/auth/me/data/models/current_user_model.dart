import 'package:app_template/Features/auth/me/domain/entities/current_user_entity.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';

/// Wire model for `GET /users/me` — same `{user, permission_keys}` shape
/// `POST /users/login` returns, minus `token`/`session_id` (not needed here).
class CurrentUserModel {
  final AuthUserModel user;
  final List<String> permissionKeys;
  final bool isSuperAdmin;

  const CurrentUserModel({
    required this.user,
    this.permissionKeys = const [],
    this.isSuperAdmin = false,
  });

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    return CurrentUserModel(
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      permissionKeys: (json['permission_keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isSuperAdmin: json['is_super_admin'] == true,
    );
  }

  CurrentUserEntity toEntity() => CurrentUserEntity(
        user: user.toEntity(),
        permissionKeys: permissionKeys,
        isSuperAdmin: isSuperAdmin,
      );
}
