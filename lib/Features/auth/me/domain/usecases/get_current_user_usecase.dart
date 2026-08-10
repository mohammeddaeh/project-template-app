import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/me/domain/entities/current_user_entity.dart';
import 'package:app_template/Features/auth/me/domain/repositories/me_repository.dart';

/// Silent background refresh after a cached session is restored (splash) —
/// see docs/reference/session_permission_integrity.md §6/§10. No dedicated
/// Cubit: this call drives no visible loading UI, it only re-syncs
/// [CurrentUserRepository] + its local cache in the background.
@injectable
class GetCurrentUserUseCase
    extends BaseUseCase<Either<Failure, CurrentUserEntity>, NoParams> {
  GetCurrentUserUseCase(this._repository);

  final MeRepository _repository;

  @override
  Future<Either<Failure, CurrentUserEntity>> call(covariant NoParams params) =>
      _repository.getCurrentUser();
}
