import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/change_password/data/datasources/change_password_remote_datasource.dart';
import 'package:app_template/Features/auth/change_password/domain/params/change_password_params.dart';
import 'package:app_template/Features/auth/change_password/domain/repositories/change_password_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ChangePasswordRepository)
class ChangePasswordRepositoryImpl extends BaseRepository
    implements ChangePasswordRepository {
  ChangePasswordRepositoryImpl(this._dataSource, HandleBodyResponse handler)
    : super(handler);

  final ChangePasswordRemoteDataSource _dataSource;

  /// ## A wrong current password is a 422, not a 401
  ///
  /// This request is authenticated, so a 401 would mean the **session** is
  /// invalid — and the central handler answers that by signing the user out.
  /// If the backend returned 401 for "your current password is wrong", mistyping
  /// one field would eject the user from the app, which reads as a crash rather
  /// than a correction.
  ///
  /// So the wrong-password case must arrive as a 4xx business failure carrying
  /// the server's message. If your backend disagrees, fix the backend: adding a
  /// special case here cannot help, because `AuthInterceptor` has already
  /// cleared the session by the time this code runs.
  @override
  Future<Either<Failure, void>> changePassword(ChangePasswordParams params) =>
      handle(() async {
        final res = await _dataSource.changePassword(
          currentPassword: params.currentPassword,
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
