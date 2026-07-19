part of 'sync_manager_cubit.dart';

/// State emitted by [SyncManagerCubit].
sealed class SyncManagerState {
  const SyncManagerState();
}

/// Sync is idle — no active operation.
final class SyncIdle extends SyncManagerState {
  const SyncIdle();
}

/// Sync is currently running.
final class SyncRunning extends SyncManagerState {
  const SyncRunning();
}

/// Last sync completed successfully.
final class SyncSuccess extends SyncManagerState {
  const SyncSuccess({required this.pendingCount, this.completedAt});

  /// Number of items still in the pending queue after this cycle.
  final int pendingCount;
  final DateTime? completedAt;
}

/// Last sync ended with a failure.
final class SyncFailedState extends SyncManagerState {
  const SyncFailedState({required this.failure});
  final Failure failure;
}

/// There are one or more entities in [SyncStatus.conflicted] state.
final class ConflictDetected extends SyncManagerState {
  const ConflictDetected({
    required this.entityName,
    required this.entityId,
    required this.conflictFields,
    required this.serverSnapshot,
  });

  final String entityName;
  final String entityId;
  final List<String> conflictFields;
  final Map<String, dynamic> serverSnapshot;
}
