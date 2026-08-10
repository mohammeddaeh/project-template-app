import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/change_password/domain/params/change_password_params.dart';
import 'package:app_template/Features/auth/change_password/domain/repositories/change_password_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ChangePasswordUseCase
    extends BaseUseCase<Either<Failure, void>, ChangePasswordParams> {
  ChangePasswordUseCase(this._repository);

  final ChangePasswordRepository _repository;

  @override
  Future<Either<Failure, void>> call(covariant ChangePasswordParams params) =>
      _repository.changePassword(params);
}
