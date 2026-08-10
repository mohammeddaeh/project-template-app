import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/login/data/datasources/auth_remote_datasource.dart';
import 'package:app_template/Features/auth/login/domain/entities/login_entity.dart';
import 'package:app_template/Features/auth/login/domain/params/login_params.dart';
import 'package:app_template/Features/auth/login/domain/repositories/login_repository.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';
import 'package:app_template/core/infra/session/session_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LoginRepository)
class LoginRepositoryImpl extends BaseRepository implements LoginRepository {
  LoginRepositoryImpl(
    this._dataSource,
    this._sessionRepository,
    this._currentUserRepository,
    HandleBodyResponse handler,
  ) : super(handler);

  final AuthRemoteDataSource _dataSource;
  final SessionRepository _sessionRepository;
  final CurrentUserRepository _currentUserRepository;

  @override
  Future<Either<Failure, LoginEntity>> login(LoginParams params) =>
      handle(() async {
        final res = await _dataSource.login(params.email, params.password);

        if (res.error != null) {
          return Left(_mapLoginError(res.error!, res.message));
        }

        if (res.data == null) {
          return const Left(BusinessFailure(statusCode: 400));
        }

        final entity = res.data!.toEntity();
        await _sessionRepository.saveToken(entity.token);
        _currentUserRepository.setCurrentUser(
          entity.user,
          permissionKeys: entity.permissionKeys.toSet(),
          isSuperAdmin: entity.isSuperAdmin,
        );
        return Right(entity);
      });

  Failure _mapLoginError(ApiError error, String message) {
    if (error.code == 401) {
      return LoginFailure(serverMessage: message);
    }

    if (error.code == 403) {
      final accountStatus = error.data?['account_status'] as String?;
      return switch (accountStatus) {
        'pending_approval' =>
          LoginPendingApprovalFailure(serverMessage: message),
        'rejected' => LoginRejectedFailure(
            reason: error.data?['rejection_reason'] as String?,
            serverMessage: message,
          ),
        'suspended' => LoginSuspendedFailure(serverMessage: message),
        'disabled' => LoginDisabledFailure(serverMessage: message),
        _ => ForbiddenFailure(serverMessage: message),
      };
    }

    return BusinessFailure(
      statusCode: error.code ?? 400,
      serverMessage: message.isNotEmpty ? message : null,
    );
  }
}
