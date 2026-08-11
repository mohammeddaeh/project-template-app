import 'package:equatable/equatable.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

/// What a successful sign-in yields.
///
/// ## `permissionKeys` and `isSuperAdmin` were removed (2026-08-11)
///
/// Both were read off the login response, defaulted to `const []` and `false`,
/// and **no endpoint has ever sent either**. `backend_template` states plainly
/// that authorization is out of scope: roles differ so much between projects
/// that a template imposing one hands every new project a model it did not ask
/// for (see `backend_template/CLAUDE.md` → "ما لم يُبنَ بعد").
///
/// The defaults meant nothing crashed — which is precisely the problem. The
/// template shipped a permission structure that was **empty on every request**,
/// and a screen hiding a button behind `permissionKeys.contains(...)` would
/// have hidden it forever, correctly by the code and wrongly by intent.
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
