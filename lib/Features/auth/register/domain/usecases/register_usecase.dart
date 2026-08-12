import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/register/domain/params/register_params.dart';
import 'package:app_template/Features/auth/register/domain/repositories/register_repository.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

@injectable
class RegisterUseCase
    extends BaseUseCase<Either<Failure, AuthUser>, RegisterParams> {
  RegisterUseCase(this._repository);

  final RegisterRepository _repository;

  @override
  Future<Either<Failure, AuthUser>> call(covariant RegisterParams params) =>
      _repository.register(params);
}
