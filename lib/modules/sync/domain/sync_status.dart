/// Entity sync state — tracks the lifecycle of a local entity relative to server.
enum SyncStatus {
  /// Entity exists locally and is up-to-date with the server.
  synced,

  /// A create/update/delete operation is queued — generic pending state.
  /// Use specific variants below for finer-grained UI display.
  pending,

  /// Entity was created locally; not yet acknowledged by server.
  pendingCreate,

  /// Entity was updated locally; the update has not yet been pushed.
  pendingUpdate,

  /// Entity was deleted locally; the deletion has not yet been pushed.
  pendingDelete,

  /// Server returned HTTP 409 — requires conflict resolution.
  /// Awaits [SyncConflictResolver] or user action (for [SyncConflictStrategy.manual]).
  conflicted,

  /// All retry attempts exhausted — job is in dead-letter state.
  /// Requires manual intervention or full re-bootstrap.
  failed;

  static SyncStatus fromRaw(String raw) => switch (raw) {
        'synced'        => SyncStatus.synced,
        'pending'       => SyncStatus.pending,
        'pendingCreate' => SyncStatus.pendingCreate,
        'pendingUpdate' => SyncStatus.pendingUpdate,
        'pendingDelete' => SyncStatus.pendingDelete,
        'conflicted'    => SyncStatus.conflicted,
        'failed'        => SyncStatus.failed,
        _               => SyncStatus.pending,
      };

  String get raw => name;

  /// Returns true for any state that means a write is in-flight or queued.
  bool get isPending => switch (this) {
        SyncStatus.pending ||
        SyncStatus.pendingCreate ||
        SyncStatus.pendingUpdate ||
        SyncStatus.pendingDelete =>
          true,
        _ => false,
      };

  bool get isTerminal =>
      this == SyncStatus.failed || this == SyncStatus.conflicted;
}

/// Operation type enqueued in [SyncQueue].
enum SyncJobType {
  create,
  update,
  delete;

  static SyncJobType fromRaw(String raw) => switch (raw) {
        'create' => SyncJobType.create,
        'update' => SyncJobType.update,
        'delete' => SyncJobType.delete,
        _        => SyncJobType.update,
      };

  String get raw => name;
}

/// Strategy used by [SyncConflictResolver] when server returns HTTP 409.
enum SyncConflictStrategy {
  /// Apply server version — discard local change. Default for shared data.
  serverWins,

  /// Re-push local version with [X-Force-Override] header.
  /// Backend must support this header to avoid re-conflicting.
  clientWins,

  /// Compare [updated_at] timestamps — the newer write wins.
  /// Suitable for peer data where neither side has authority.
  lastWriteWins,

  /// Apply a per-field merge: non-conflicting fields from client,
  /// conflicting fields (listed in 409 [conflict_fields]) from server.
  /// Requires [ConflictFailure.conflictFields] to be populated by the backend.
  merge,

  /// Mark entity as [SyncStatus.conflicted] and emit a [ConflictDetected] event.
  /// The user resolves in the conflict UI — no automatic resolution.
  manual,
}
