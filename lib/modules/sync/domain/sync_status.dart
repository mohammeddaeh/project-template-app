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
  delete,

  /// Bytes the device owes the server.
  ///
  /// The enum carried only the three above while `SyncQueueJob.priority`
  /// documented «90 = file uploads» — an ordering for a job type that could not
  /// be expressed. Priority now means something on both ends.
  fileUpload;

  static SyncJobType fromRaw(String raw) => switch (raw) {
        'create'     => SyncJobType.create,
        'update'     => SyncJobType.update,
        'delete'     => SyncJobType.delete,
        'fileUpload' => SyncJobType.fileUpload,
        _            => SyncJobType.update,
      };

  String get raw => name;
}

/// Strategy used by [SyncConflictResolver] when server returns HTTP 409.
enum SyncConflictStrategy {
  /// Apply server version — discard local change. Default for shared data.
  serverWins,

  /// Keep the local content and make it win — by **rebasing onto the server's
  /// current version**, not by asking the server to ignore its own rules.
  ///
  /// ## What this used to say, and why it could never work
  ///
  /// «Re-push local version with `X-Force-Override` header. Backend must
  /// support this header.» No backend in this project ever did, and the
  /// resulting path was a closed loop: 409 → re-queue unchanged → the same
  /// stale base version → 409 → … until `max_retries` marked the job `failed`.
  /// A strategy named "the client wins" ended with the client losing, five
  /// attempts later, silently.
  ///
  /// ## What it does now
  ///
  /// The 409 carries `server_version`. The resolver takes the version number
  /// from it and stamps it onto the queued payload, leaving the **content**
  /// untouched. The retry then arrives with a base the server agrees with, so
  /// the optimistic check passes and the local content is written.
  ///
  /// No header, no special endpoint, no server-side exception to the concurrency
  /// rule — the client simply says "I have seen your version, and I still mean
  /// this." Which is what winning a conflict actually is.
  ///
  /// Falls back to [manual] when the server sends no `server_version`: without
  /// a base to rebase onto there is nothing to do but ask a person.
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
