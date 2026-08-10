import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/boundary/base_repository.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';
import 'package:app_template/Features/auth/me/data/datasources/me_remote_datasource.dart';
import 'package:app_template/Features/auth/me/domain/entities/current_user_entity.dart';
import 'package:app_template/Features/auth/me/domain/repositories/me_repository.dart';

@LazySingleton(as: MeRepository)
class MeRepositoryImpl extends BaseRepository implements MeRepository {
  MeRepositoryImpl(this._dataSource, HandleBodyResponse handler)
      : super(handler);

  final MeRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, CurrentUserEntity>> getCurrentUser() =>
      handle(() async {
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

        return Right(res.data!.toEntity());
      });
}
