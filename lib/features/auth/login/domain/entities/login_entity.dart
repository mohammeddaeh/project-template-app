import 'package:equatable/equatable.dart';
import 'package:app_template/features/auth/shared/entities/auth_user.dart';

/// What a successful sign-in yields.
///
/// ## No `permissionKeys` and no `isSuperAdmin`
///
/// The login response sends **neither**. `backend_template` states plainly
/// that authorization is out of scope: roles differ so much between projects
/// that a template imposing one hands every new project a model it did not ask
/// for (see `backend_template/CLAUDE.md` → "ما لم يُبنَ بعد").
///
/// Defaulting them to `const []` and `false` would crash nothing — which is
/// precisely the problem: a permission structure **empty on every request**,
/// and a screen hiding a button behind `permissionKeys.contains(...)` hides it
/// forever, correctly by the code and wrongly by intent.
///
/// **Adding authorization** is a change in both halves, in this order:
/// the server issues the claims (a `roles`/`permissions` join and its own
/// `requirePermission` middleware), then this entity carries them. Doing it in
/// the other order is what produced the field that existed for nobody.
class LoginEntity extends Equatable {
  const LoginEntity({
    required this.token,
    required this.user,
    this.sessionId = 0,
  });

  /// The opaque session token. Revocable server-side, which is why there is no
  /// separate refresh token — `POST /auth/refresh` rotates this one in place.
  final String token;

  final AuthUser user;

  /// Identifies the session this sign-in opened, matching `is_current` on
  /// `GET /auth/sessions`.
  final int sessionId;

  @override
  List<Object?> get props => [token, user, sessionId];
}
