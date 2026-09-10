import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';

abstract interface class LogoutRepository {
  Future<Either<Failure, void>> logout();
}
