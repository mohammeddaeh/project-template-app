import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/forgot_password/domain/params/request_reset_params.dart';
import 'package:app_template/Features/auth/forgot_password/domain/params/reset_password_params.dart';

abstract class PasswordResetRepository {
  /// Asks the server to send a reset code.
  ///
  /// **Succeeds even when the address is not registered** — see the
  /// implementation for why that is the correct behaviour and not a missing
  /// check.
  Future<Either<Failure, void>> requestReset(RequestResetParams params);

  /// Consumes the code and sets the new password.
  Future<Either<Failure, void>> resetPassword(ResetPasswordParams params);
}
