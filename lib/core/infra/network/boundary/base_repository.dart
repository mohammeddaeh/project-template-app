import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/network/rest/handle_body_response.dart';

/// Abstract base class that enforces [HandleBodyResponse] as the ONLY
/// error-handling boundary for all repositories.
abstract class BaseRepository {
  const BaseRepository(this._handler);

  final HandleBodyResponse _handler;

  @protected
  Future<Either<Failure, T>> handle<T>(BodyCall<T> call) =>
      _handler.body(call);
}
