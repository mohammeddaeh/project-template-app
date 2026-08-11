import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/shared/current_user_repository.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';
import 'package:app_template/Features/auth/verify_email/data/datasources/verify_email_remote_datasource.dart';
import 'package:app_template/Features/auth/verify_email/domain/repositories/verify_email_repository.dart';

@LazySingleton(as: VerifyEmailRepository)
class VerifyEmailRepositoryImpl extends BaseRepository
    implements VerifyEmailRepository {
  VerifyEmailRepositoryImpl(
    this._dataSource,
    this._currentUserRepository,
    HandleBodyResponse handler,
  ) : super(handler);

  final VerifyEmailRemoteDataSource _dataSource;
  final CurrentUserRepository _currentUserRepository;

  @override
  Future<Either<Failure, AuthUser>> verifyEmail(String code) => handle(() async {
        final res = await _dataSource.verifyEmail(code);

        if (res.error != null) {
          return Left(
            BusinessFailure(
              statusCode: res.error!.code ?? 400,
              serverMessage: res.message.isNotEmpty ? res.message : null,
            ),
          );
        }

        final cached = _currentUserRepository.currentUser;
        if (cached == null || res.data == null) {
          // Verification succeeded on the server either way; only the local
          // mirror is missing. Reported as a failure rather than silently
          // shrugging, because the screen's next act is to route on the new
          // status — and routing on a status we do not have would land the user
          // somewhere arbitrary.
          return const Left(BusinessFailure(statusCode: 500));
        }

        final updated = res.data!.applyTo(cached);

        // Fed straight back so re-entering any screen reflects the new status
        // without a `GET /users/me` round trip — the same thing
        // `RegistrationStatusCubit` does after a resubmit.
        _currentUserRepository.setCurrentUser(
          updated,
          permissionKeys: _currentUserRepository.permissionKeys,
          // Carried through unchanged: this call changes the user's own record,
          // not their authority. Letting it default to false would strip a
          // Super Admin's controls as a side effect of confirming an email.
          isSuperAdmin: _currentUserRepository.isSuperAdmin,
        );
        return Right(updated);
      });

  @override
  Future<Either<Failure, void>> resendVerification() => handle(() async {
        final res = await _dataSource.resendVerification();

        if (res.error != null) {
          // The server's own message is passed through rather than replaced by
          // a local string: only it knows which refusal this was — a cooldown,
          // an already-verified account, or verification being switched off —
          // and the three need different words. `message_key` in
          // `error.data` is there for a caller that must branch programmatically.
          return Left(
            BusinessFailure(
              statusCode: res.error!.code ?? 400,
              serverMessage: res.message.isNotEmpty ? res.message : null,
            ),
          );
        }
        return const Right(null);
      });
}
