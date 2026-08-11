import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/domain/base_usecase.dart';
import 'package:app_template/core/foundation/domain/no_params.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/me/domain/repositories/me_repository.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

/// Re-reads the signed-in account from the server.
///
/// Two callers, both deliberate:
///
/// - `SessionSyncService` — once after a cached token restores a session, and
///   again on every foreground resume. This is how a status change made
///   server-side (an account disabled, an address verified elsewhere) reaches a
///   client that has not signed in again.
/// - `ProfileScreen` — pull-to-refresh.
///
/// No dedicated Cubit for the first case: the call drives no visible loading
/// UI, it only re-syncs [CurrentUserRepository] and its local cache.
@injectable
class GetCurrentUserUseCase
    extends BaseUseCase<Either<Failure, AuthUser>, NoParams> {
  GetCurrentUserUseCase(this._repository);

  final MeRepository _repository;

  @override
  Future<Either<Failure, AuthUser>> call(covariant NoParams params) =>
      _repository.getCurrentUser();
}
