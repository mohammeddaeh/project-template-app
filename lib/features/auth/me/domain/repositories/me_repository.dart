import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/features/auth/shared/entities/auth_user.dart';

/// Returns [AuthUser] directly, not a wrapper.
///
/// `/me` returns the account and nothing beside it, so a wrapper would hold
/// exactly one field — and a type whose only job is to hold another type is a
/// level of indirection that has to be unwrapped at every call site for
/// nothing.
abstract interface class MeRepository {
  Future<Either<Failure, AuthUser>> getCurrentUser();
}
