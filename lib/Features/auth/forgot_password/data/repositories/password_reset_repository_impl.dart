import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/forgot_password/data/datasources/password_reset_remote_datasource.dart';
import 'package:app_template/Features/auth/forgot_password/domain/params/request_reset_params.dart';
import 'package:app_template/Features/auth/forgot_password/domain/params/reset_password_params.dart';
import 'package:app_template/Features/auth/forgot_password/domain/repositories/password_reset_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PasswordResetRepository)
class PasswordResetRepositoryImpl extends BaseRepository
    implements PasswordResetRepository {
  PasswordResetRepositoryImpl(this._dataSource, HandleBodyResponse handler)
    : super(handler);

  final PasswordResetRemoteDataSource _dataSource;

  /// ## The server must answer the same way for a known and an unknown address
  ///
  /// A "no account with that email" error turns this endpoint into a free
  /// membership oracle: anyone can test addresses one at a time and learn who
  /// has an account here. That is a real leak for any app where membership
  /// itself is private, and it costs nothing to avoid.
  ///
  /// So the screen says "if that address is registered, we sent a code" and
  /// this method treats a success as a success without asking whether an email
  /// was actually dispatched. **If your backend returns 404 for unknown
  /// addresses, fix the backend** — do not add a branch here to hide it, since
  /// the response time and status code still differ and still leak.
  @override
  Future<Either<Failure, void>> requestReset(RequestResetParams params) =>
      handle(() async {
        final res = await _dataSource.requestReset(params.email);

        if (res.error != null) {
          return Left(
            BusinessFailure(
              statusCode: res.error!.code ?? 400,
              serverMessage: res.message.isNotEmpty ? res.message : null,
            ),
          );
        }
        return const Right(null);
      });

  /// A rejected code is a `BusinessFailure` carrying the server's message,
  /// because only the server knows which of the three it was — wrong, expired,
  /// or already used — and the three need different words. Inventing a local
  /// "invalid code" string here would flatten them into one.
  @override
  Future<Either<Failure, void>> resetPassword(ResetPasswordParams params) =>
      handle(() async {
        final res = await _dataSource.resetPassword(
          email: params.email,
          token: params.token,
          newPassword: params.newPassword,
        );

        if (res.error != null) {
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
