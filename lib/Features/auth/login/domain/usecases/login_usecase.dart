import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/Features/auth/login/domain/params/login_params.dart';
import 'package:app_template/Features/auth/login/domain/repositories/login_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginUseCase extends BaseUseCase<Either<Failure, LoginEntity>, LoginParams> {
  LoginUseCase(this._repository);

  final LoginRepository _repository;

  @override
  Future<Either<Failure, LoginEntity>> call(covariant LoginParams params) =>
      _repository.login(params);
}
