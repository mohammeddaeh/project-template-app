import 'package:app_template/core/foundation/contracts/unsynced_work_probe.dart';
import 'package:app_template/core/platform/logging/log_service.dart';

import '../domain/sync_queue_repository.dart';

/// [UnsyncedWorkProbe] backed by the real queue.
///
/// Registered by `registerSyncCore` **over** the `NoUnsyncedWorkProbe` default,
/// so callers that guard destructive actions get a true answer the moment the
/// module is switched on, and never have to ask whether it is.
class SyncUnsyncedWorkProbe implements UnsyncedWorkProbe {
  const SyncUnsyncedWorkProbe(this._queueRepository);

  final SyncQueueRepository _queueRepository;

  @override
  Future<int> pendingOperations() async {
    try {
      return await _queueRepository.countPendingJobs();
    } catch (e) {
      // A fallback path logs. And it answers **1, not 0**: this number gates
      // destructive actions, so an unknown answer must read as "there might be
      // something to lose". Answering 0 on a failed count would wave through
      // the exact sign-out this probe exists to stop.
      LogService.error(
        'Could not count pending sync operations — reporting 1 so anything '
        'destructive stops and asks rather than assuming nothing is at stake.',
        tag: 'SYNC',
        error: e,
      );
      return 1;
    }
  }
}
