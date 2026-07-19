import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/failure_mapper_registry.dart';
import 'package:injectable/injectable.dart';

typedef BodyCall<RV> = Future<Either<Failure, RV>> Function();

/// The SINGLE error-handling boundary wrapping all repository calls.
///
/// Every exception is routed through [FailureMapperRegistry.map], which
/// dispatches to the correct [FailureMapper] (Dio) and logs centrally.
@lazySingleton
class HandleBodyResponse {
  Future<Either<Failure, RV>> body<RV>(BodyCall<RV> call) async {
    try {
      return await call();
    } catch (e) {
      return Left(FailureMapperRegistry.map(e, source: 'REST'));
    }
  }
}
