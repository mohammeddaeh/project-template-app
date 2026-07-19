import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'device_session.dart';

abstract interface class DeviceSessionRepository {
  /// Returns the list of active sessions for the current user.
  Future<Either<Failure, List<DeviceSession>>> getActiveSessions();

  /// Revokes the session identified by [deviceSessionId].
  /// Only callable from the primary device.
  Future<Either<Failure, void>> revokeSession(String deviceSessionId);

  /// Revokes all sessions except the current one.
  /// Only callable from the primary device.
  Future<Either<Failure, void>> revokeAllExceptCurrent();

  /// Logs out the current device (revokes this session only).
  Future<Either<Failure, void>> logout();
}
