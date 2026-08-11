import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

abstract interface class VerifyEmailRepository {
  /// Spends [code]. Returns the user with their **new** status applied, so the
  /// caller never has to guess what verification unlocked.
  Future<Either<Failure, AuthUser>> verifyEmail(String code);

  /// Asks for a fresh code. Issuing one **invalidates the previous** — so a
  /// user who requested twice must use the newer message, and an attacker
  /// cannot stack independent guess budgets by spamming resends.
  Future<Either<Failure, void>> resendVerification();
}
