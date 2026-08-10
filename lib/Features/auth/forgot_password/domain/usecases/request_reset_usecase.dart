import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/forgot_password/domain/params/request_reset_params.dart';
import 'package:app_template/Features/auth/forgot_password/domain/repositories/password_reset_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class RequestResetUseCase
    extends BaseUseCase<Either<Failure, void>, RequestResetParams> {
  RequestResetUseCase(this._repository);

  final PasswordResetRepository _repository;

  @override
  Future<Either<Failure, void>> call(covariant RequestResetParams params) =>
      _repository.requestReset(params);
}
