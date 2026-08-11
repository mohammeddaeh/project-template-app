import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/me/data/datasources/me_remote_datasource.dart';
import 'package:app_template/Features/auth/me/domain/repositories/me_repository.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

@LazySingleton(as: MeRepository)
class MeRepositoryImpl extends BaseRepository implements MeRepository {
  MeRepositoryImpl(
    this._dataSource,
    this._currentUserRepository,
    HandleBodyResponse handler,
  ) : super(handler);

  final MeRemoteDataSource _dataSource;
  final CurrentUserRepository _currentUserRepository;

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() => handle(() async {
    final res = await _dataSource.getCurrentUser();

    if (res.error != null) {
      return Left(BusinessFailure(
        statusCode: res.error?.code ?? 400,
        serverMessage: res.message.isNotEmpty ? res.message : null,
      ));
    }

    if (res.data == null) {
      return const Left(BusinessFailure(statusCode: 400));
    }

    // Published here rather than by each caller: `/me` is the authority on who
    // is signed in, and a caller that fetched it without publishing would leave
    // every listener holding the stale record it just disproved.
    _currentUserRepository.setCurrentUser(res.data!);
    return Right(res.data!);
  });
}
