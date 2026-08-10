import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/logout/domain/repositories/logout_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class LogoutUseCase extends BaseUseCase<Either<Failure, void>, NoParams> {
  LogoutUseCase(this._repository);

  final LogoutRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      _repository.logout();
}
