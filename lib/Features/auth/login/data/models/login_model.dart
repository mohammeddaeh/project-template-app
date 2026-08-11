import 'package:app_template/Features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/Features/auth/shared/models/auth_user_model.dart';

/// Wire shape of `data` on `POST /api/v1/account/login`.
///
/// ## The key is `account`, not `user`
///
/// This model read `json['user']` until 2026-08-11, against a server that has
/// always sent `account` (`loginResponseSchema` in
/// `backend_template/src/features/account/dtos/account.dto.ts`). The cast of a
/// missing key to `Map<String, dynamic>` threw, `HandleBodyResponse` caught it
/// like any other exception, and the result was **a successful sign-in that
/// showed a generic error**: the server issued a real session, wrote a real
/// row, logged `200 OK`, and the screen said something went wrong.
///
/// That failure mode is why `test/wire_contract_test.dart` now parses the
/// literal OpenAPI example rather than a fixture written from memory — the two
/// halves agreed on shape in prose and disagreed on one word in code, and
/// neither `dart analyze` nor `tsc` can see across the wire.
class LoginModel {
  final String token;
  final AuthUserModel account;

  /// The session this sign-in opened.
  ///
  /// Kept rather than discarded: it is what `is_current` on
  /// `GET /auth/sessions` is compared against, so a devices screen that wants
  /// to mark "this device" without a round trip already has the answer.
  final int sessionId;

  const LoginModel({
    required this.token,
    required this.account,
    this.sessionId = 0,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      token: json['token'] as String? ?? '',
      account: AuthUserModel.fromJson(json['account'] as Map<String, dynamic>),
      sessionId: json['session_id'] as int? ?? 0,
    );
  }

  LoginEntity toEntity() => LoginEntity(
        token: token,
        user: account.toEntity(),
        sessionId: sessionId,
      );
}
