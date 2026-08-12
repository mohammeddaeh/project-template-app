import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/register/data/datasources/register_remote_datasource.dart';
import 'package:app_template/Features/auth/register/domain/params/register_params.dart';
import 'package:app_template/Features/auth/register/domain/repositories/register_repository.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

@LazySingleton(as: RegisterRepository)
class RegisterRepositoryImpl extends BaseRepository
    implements RegisterRepository {
  RegisterRepositoryImpl(this._dataSource, HandleBodyResponse handler)
      : super(handler);

  final RegisterRemoteDataSource _dataSource;

  /// Deliberately does **not** touch `SessionRepository` or
  /// `CurrentUserRepository`.
  ///
  /// Registration returns no token, so there is no session to save; and writing
  /// the account into `CurrentUserRepository` without one would make
  /// `currentUser` non-null for someone who is not signed in — every screen
  /// that gates on it would then render for an unauthenticated user. The screen
  /// routes to sign-in, and `LoginRepositoryImpl` publishes both.
  @override
  Future<Either<Failure, AuthUser>> register(RegisterParams params) =>
      handle(() async {
        final res = await _dataSource.register(params);

        if (res.error != null) {
          // Every refusal here — 409 "email already registered", 422 "password
          // too weak", 429 "too many registrations" — travels as a
          // `BusinessFailure` carrying the server's own message.
          //
          // Deliberately NOT `ConflictFailure` for the 409: that type is
          // sync-internal and `FailureUiMapper` maps it to `Silent()`, so
          // using it would make the one refusal a user most needs to read
          // display nothing at all. It is also the only refusal here with an
          // obvious next step, and the server already words it.
          return Left(
            BusinessFailure(
              statusCode: res.error!.code ?? 400,
              serverMessage: res.message.isNotEmpty ? res.message : null,
            ),
          );
        }

        if (res.data == null) {
          return const Left(BusinessFailure(statusCode: 400));
        }

        return Right(res.data!);
      });
}
