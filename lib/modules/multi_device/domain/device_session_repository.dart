import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'device_session.dart';

abstract interface class DeviceSessionRepository {
  /// Every live session for the calling account, most recently active first.
  Future<Either<Failure, List<DeviceSession>>> getActiveSessions();

  /// Ends one session.
  ///
  /// Any session may end any session of the **same account** — the server
  /// checks ownership, not seniority. The old "only the primary device may
  /// revoke" rule was removed because it disarmed the feature in the one case
  /// it exists for: a lost or stolen primary device.
  Future<Either<Failure, void>> revokeSession(int id);

  /// Ends every other session, sparing the caller's own — signing yourself out
  /// while securing your account reads as a malfunction. Returns how many
  /// ended, so the confirmation can state a number instead of "done".
  Future<Either<Failure, int>> revokeOthers();
}
