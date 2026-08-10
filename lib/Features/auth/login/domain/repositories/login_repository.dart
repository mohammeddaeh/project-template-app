import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/Features/auth/login/domain/params/login_params.dart';

abstract interface class LoginRepository {
  Future<Either<Failure, LoginEntity>> login(LoginParams params);
}
