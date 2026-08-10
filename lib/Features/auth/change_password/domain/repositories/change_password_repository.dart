import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/change_password/domain/params/change_password_params.dart';

abstract class ChangePasswordRepository {
  Future<Either<Failure, void>> changePassword(ChangePasswordParams params);
}
