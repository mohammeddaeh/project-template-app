import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/Features/auth/shared/entities/auth_user.dart';

/// Returns [AuthUser] directly, not a wrapper.
///
/// `CurrentUserEntity` used to sit here carrying `permissionKeys` and
/// `isSuperAdmin` beside the user — two fields no endpoint has ever sent. With
/// them gone the wrapper held exactly one field, and a type whose only job is
/// to hold another type is a level of indirection that has to be unwrapped at
/// every call site for nothing.
abstract interface class MeRepository {
  Future<Either<Failure, AuthUser>> getCurrentUser();
}
