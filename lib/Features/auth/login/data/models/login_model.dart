import 'package:app_template/Features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';

class LoginModel {
  final String token;
  final AuthUserModel user;
  final List<String> permissionKeys;
  final bool isSuperAdmin;

  const LoginModel({
    required this.token,
    required this.user,
    this.permissionKeys = const [],
    this.isSuperAdmin = false,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      token: json['token'] as String? ?? '',
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      permissionKeys: (json['permission_keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isSuperAdmin: json['is_super_admin'] == true,
    );
  }

  LoginEntity toEntity() => LoginEntity(
        token: token,
        user: user.toEntity(),
        permissionKeys: permissionKeys,
        isSuperAdmin: isSuperAdmin,
      );
}
