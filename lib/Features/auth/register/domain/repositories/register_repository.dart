import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/register/domain/params/register_params.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

abstract interface class RegisterRepository {
  /// Returns the created account — **not** a session.
  ///
  /// `POST /account/register` answers `201` with the account and no token, by
  /// design: registering and signing in are separate acts, and a server that
  /// conflated them would have to decide what a `pending_verification` session
  /// may do before the client ever asked.
  Future<Either<Failure, AuthUser>> register(RegisterParams params);
}
