import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/logout/data/datasources/logout_remote_datasource.dart';
import 'package:app_template/Features/auth/logout/domain/repositories/logout_repository.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LogoutRepository)
class LogoutRepositoryImpl extends BaseRepository implements LogoutRepository {
  LogoutRepositoryImpl(
    this._remoteDataSource,
    this._sessionRepository,
    this._currentUserRepository,
    HandleBodyResponse handler,
  ) : super(handler);

  final LogoutRemoteDataSource _remoteDataSource;
  final SessionRepository _sessionRepository;
  final CurrentUserRepository _currentUserRepository;

  @override
  Future<Either<Failure, void>> logout() => handle(() async {
        final res = await _remoteDataSource.logout();
        if (res.error == null) {
          _sessionRepository.clearSession();
          _currentUserRepository.clear();
          return const Right(null);
        }
        return Left(BusinessFailure(
          statusCode: res.error?.code ?? 400,
          serverMessage: res.message.isNotEmpty ? res.message : null,
        ));
      });
}
