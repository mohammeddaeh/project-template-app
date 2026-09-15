import 'sync_queue_job.dart';
import 'sync_status.dart';

abstract class SyncQueueRepository {
  Future<void> enqueue({
    required String jobId,
    required SyncJobType type,
    required String entityName,
    required String entityId,
    required String payloadJson,
    required int contractVersion,
    int maxRetries = 5,
    int priority = 10,
    String? idempotencyKey,
  });

  Future<List<SyncQueueJob>> getDueJobs({required int nowMs, required int limit});

  Future<List<SyncQueueJob>> getAllJobs({int limit = 500});

  Future<void> updateJobPayloadAndVersion({
    required String jobId,
    required String payloadJson,
    required int contractVersion,
  });

  Future<void> markJobSuccess({required String jobId});

  Future<void> markJobRetry({
    required String jobId,
    required int retryCount,
    required int nextRetryAt,
    required String? lastError,
  });

  Future<void> markEntitySyncState({
    required String entityName,
    required String localId,
    required SyncStatus status,
    String? serverId,
    String? lastError,
  });

  /// Returns count of jobs in pending/retrying state.
  Future<int> countPendingJobs();

  /// Resets a dead-lettered job (`retry_count >= max_retries`) so it becomes
  /// due again.
  ///
  /// The only recovery path for a job whose retry budget ran out for a
  /// *transient* reason — a maintenance window, a week in a coverage
  /// dead-zone — rather than because the write itself is invalid. Without
  /// this, `getDueJobs` excludes the row forever and the work it represents
  /// is lost until someone reproduces it by hand.
  ///
  /// Returns `false` if no dead-lettered job matches [jobId] — reviving a job
  /// that is still retrying, already synced, or does not exist is a no-op,
  /// not an error.
  Future<bool> reviveJob({required String jobId});
}
