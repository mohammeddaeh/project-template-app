import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';

/// What `POST /auth/verify-email` returns: the account's **new** state.
///
/// ## Why the server sends this rather than an empty 200
///
/// Proving an address advances the lifecycle — in Qirtas from
/// `pending_verification` to `pending_approval`. That transition is a server
/// rule. If the response were empty, this client would have to either hard-code
/// "verification means pending_approval next" (a rule it does not own and will
/// eventually get wrong when the server's changes) or fire a second
/// `GET /users/me` for a fact the first response already knew.
///
/// So the new status travels back and is applied verbatim. Same shape of
/// decision as `POST /users/me/resubmit-registration`, which returns the
/// updated user.
///
/// Deliberately three fields and not a whole user: this is an authentication
/// endpoint, and the full record — roles, branch, ownership — belongs to
/// `features/identity` on the server.
class VerifiedAccountModel {
  const VerifiedAccountModel({
    required this.status,
    required this.emailVerified,
    this.emailVerifiedAt,
  });

  final String? status;
  final bool emailVerified;
  final String? emailVerifiedAt;

  factory VerifiedAccountModel.fromJson(Map<String, dynamic> json) =>
      VerifiedAccountModel(
        status: json['status'] as String?,
        emailVerified:
            json['email_verified'] == true || json['email_verified'] == 1,
        emailVerifiedAt: json['email_verified_at'] as String?,
      );

  /// Folds this new state onto the user the app already holds.
  ///
  /// A merge rather than a replacement because the payload intentionally
  /// carries only what verification changed — overwriting the cached user with
  /// it would blank out their name, phone and requested role.
  AuthUser applyTo(AuthUser user) => user.copyWith(
        status: authUserStatusFromWire(status),
        emailVerified: emailVerified,
        emailVerifiedAt: emailVerifiedAt != null
            ? DateTime.tryParse(emailVerifiedAt!)
            : null,
      );
}
