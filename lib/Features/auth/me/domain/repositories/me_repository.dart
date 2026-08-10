import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/me/domain/entities/current_user_entity.dart';

abstract interface class MeRepository {
  Future<Either<Failure, CurrentUserEntity>> getCurrentUser();
}
