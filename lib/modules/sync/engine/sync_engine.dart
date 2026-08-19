import 'dart:convert';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/infra/errors/failure_mapper_registry.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';

import '../automation/sync_feature_contract.dart';
import '../config/sync_mode.dart';
import '../config/sync_settings.dart';
import '../config/sync_settings_store.dart';
import '../data/sync_cursor_store.dart';
import '../data/sync_operations_log.dart';
import '../domain/sync_entity_record.dart';
import '../domain/sync_entity_store.dart';
import '../domain/sync_queue_job.dart';
import '../domain/sync_queue_repository.dart';
import '../domain/sync_status.dart';
import '../integration/sync_lock.dart';
import 'sync_backoff_policy.dart';
import 'sync_conflict_resolver.dart';
import 'sync_job_executor.dart';
import 'attachment_upload_manager.dart';
import 'sync_pull_executor.dart';
import '../validation/sync_contract_migrator.dart';
import '../validation/sync_contract_validator.dart';

class SyncEngine {
  SyncEngine(
    this._settingsStore,
    this._queueRepository,
    this._entityStore,
    this._backoffPolicy,
    this._getIt,
    this._migrator,
    this._validator,
    this._conflictResolver,
    this._syncLock,
    this._opsLog,
    this._cursorStore,
  );

  final SyncSettingsStore _settingsStore;
  final SyncQueueRepository _queueRepository;
  final SyncEntityStore _entityStore;
  final SyncBackoffPolicy _backoffPolicy;
  final GetIt _getIt;
  final SyncContractMigrator _migrator;
  final SyncContractValidator _validator;
  final SyncConflictResolver _conflictResolver;
  final SyncLock _syncLock;
  final SyncOperationsLog _opsLog;
  final SyncCursorStore _cursorStore;

  static int _cycleCount = 0;

  /// Full sync cycle: acquire lock → push queue → release lock.
  /// True while this isolate is inside a cycle.
  ///
  /// `SyncLock` is persisted, and persisting it costs an `await` between the
  /// read and the write — a window in which a second trigger reads "free" and
  /// both proceed. Three independent triggers (the periodic timer, the
  /// connectivity listener, a manual tap) make that window reachable, and two
  /// cycles writing the same rows is what the lock exists to prevent.
  ///
  /// Dart's single-threaded event loop is what makes this flag sufficient
  /// *within* an isolate: check and set happen with no `await` between them, so
  /// nothing can interleave. The persisted lock still does the job it is the
  /// only one that can — surviving a process death, so a crashed cycle does not
  /// leave the next one blocked forever.
  bool _cycleInProgress = false;

  Future<void> runPendingJobs({int batchSize = 30}) async {
    // Guard first, and synchronously. Everything below may suspend.
    if (_cycleInProgress) {
      LogService.debug('SyncEngine skipped — a cycle is already running.',
          tag: 'SYNC');
      return;
    }
    _cycleInProgress = true;

    try {
      await _runCycle(batchSize: batchSize);
    } finally {
      _cycleInProgress = false;
    }
  }

  Future<void> _runCycle({required int batchSize}) async {
    // Inside the guard, so a throw from either of these cannot escape into a
    // timer callback or a stream listener as an unhandled async error — the two
    // call sites that have no `onError` and no owner.
    final SyncSettings settings;
    final bool acquired;
    try {
      settings = await _settingsStore.getSettings();
      if (settings.mode != SyncMode.active || !settings.syncEnabled) return;
      acquired = await _syncLock.tryAcquire();
    } catch (e, st) {
      LogService.error(
        'SyncEngine could not start — settings or lock unreadable.',
        tag: 'SYNC',
        error: e,
        stackTrace: st,
      );
      return;
    }

    if (!acquired) {
      LogService.debug('SyncEngine skipped — lock held.', tag: 'SYNC');
      return;
    }

    try {
      // **Push before pull, and the order is not a preference.**
      //
      // Reversed, a server row would arrive and overwrite a local edit that has
      // not been sent yet — so the user's write is lost *before it ever leaves
      // the device*, which is the one kind of loss nothing anywhere can
      // reconstruct.
      await _processPushQueue(batchSize: batchSize);
      await _processPullPhase();
      // Files last: the heaviest and slowest phase, and putting it first would
      // let one interrupted 300 MB download block a text edit measured in bytes.
      await _processFileUploads();
    } catch (e, st) {
      LogService.error('SyncEngine failed', tag: 'SYNC', error: e, stackTrace: st);
    } finally {
      // Release first, and on its own. A throw anywhere later in this block
      // would skip it and leave the lock held for its full ten-minute timeout,
      // blocking every cycle in between.
      await _syncLock.release();

      _cycleCount++;
      if (_cycleCount % 50 == 0) {
        // Trimming is housekeeping, and housekeeping must not be able to fail a
        // cycle that has already done its work — nor escape a `finally`, which
        // would replace whatever the `catch` above had just handled.
        try {
          await _opsLog.trim();
        } catch (e, st) {
          LogService.error(
            'Trimming the operations log failed — the log keeps growing, and '
            'nothing else about this cycle is affected.',
            tag: 'SYNC',
            error: e,
            stackTrace: st,
          );
        }
      }
    }
  }

  Future<void> _processPushQueue({required int batchSize}) async {
    // Build executor lookup once per sync cycle — avoids repeated GetIt.getAll()
    // calls inside the job loop (was O(n) per job; now O(1) per job).
    final executorCache = _buildExecutorCache();

    while (true) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final jobs = await _queueRepository.getDueJobs(nowMs: now, limit: batchSize);
      if (jobs.isEmpty) break;

      for (final job in jobs) {
        final executor = executorCache[job.entityName];
        if (executor == null) {
          await _queueRepository.markJobRetry(
            jobId: job.jobId,
            retryCount: job.retryCount + 1,
            nextRetryAt: _backoffPolicy.nextRetryAtMillis(
              retryCount: job.retryCount + 1,
              baseDelaySeconds: 2,
              maxDelaySeconds: 120,
            ),
            lastError: 'No executor for ${job.entityName}',
          );
          continue;
        }

        var effectiveContractVersion = job.contractVersion;
        try {
          final migration = _migrator.migratePayloadToLatest(
            entityName: job.entityName,
            payloadJson: job.payloadJson,
            fromVersion: job.contractVersion,
          );
          if (migration.migrated) {
            await _queueRepository.updateJobPayloadAndVersion(
              jobId: job.jobId,
              payloadJson: migration.payloadJson,
              contractVersion: migration.contractVersion,
            );
          }
          effectiveContractVersion = migration.contractVersion;

          _validator.validateQueuePayload(
            entityName: job.entityName,
            payloadJson: migration.payloadJson,
            contractVersion: migration.contractVersion,
          );

          if (!executor.supportedContractVersions.contains(effectiveContractVersion)) {
            throw StateError(
              'Executor "${executor.runtimeType}" does not support '
              'contract version $effectiveContractVersion for ${job.entityName}',
            );
          }
        } catch (e) {
          final nextCount = job.retryCount + 1;
          final exceeded = nextCount >= job.maxRetries;
          await _queueRepository.markEntitySyncState(
            entityName: job.entityName,
            localId: job.entityId,
            status: exceeded ? SyncStatus.failed : SyncStatus.pending,
            lastError: e.toString(),
          );
          await _queueRepository.markJobRetry(
            jobId: job.jobId,
            retryCount: nextCount,
            nextRetryAt: _backoffPolicy.nextRetryAtMillis(
              retryCount: nextCount,
              baseDelaySeconds: 2,
              maxDelaySeconds: 600,
            ),
            lastError: e.toString(),
          );
          await _opsLog.log(
            entityName: job.entityName,
            entityId: job.entityId,
            jobId: job.jobId,
            operation: SyncLogOperation.retried,
            errorCode: 'validation_error',
            errorDetail: e.toString(),
          );
          continue;
        }

        // **A throw here is one job's problem, not the cycle's.**
        //
        // This call used to sit outside any `try`. An executor that threw
        // instead of returning `Left` — which every non-2xx response does,
        // because Dio's default `validateStatus` raises — escaped the loop,
        // escaped `_processPushQueue`, and was caught only by the cycle-level
        // handler in `runPendingJobs`. Three things went with it: the remaining
        // jobs were never attempted, the pull phase never ran, and the file
        // phase never ran — all because one write got a 500.
        //
        // Worse, the job itself was left untouched: no `retry_count`, no
        // `next_retry_at`. It stayed immediately due, was picked first again
        // next cycle, threw again, and blocked everything behind it forever —
        // a queue with a permanently stuck head and no back-off anywhere.
        //
        // Routing the throw into `_handleJobFailure` gives it the same
        // accounting a returned `Left` gets, and `continue` moves on.
        final Either<Failure, SyncExecutionResult> result;
        try {
          result = await executor.execute(job, effectiveContractVersion);
        } catch (e, st) {
          // Mapped rather than wrapped: `FailureMapperRegistry` is the
          // template's one place that knows what a transport error means, and
          // it keeps this engine free of any knowledge of Dio.
          final failure = FailureMapperRegistry.map(e, source: 'sync_push');
          LogService.error(
            'Executor "${executor.runtimeType}" threw for '
            '${job.entityName}/${job.entityId} — treated as a failed job, not a '
            'failed cycle.',
            tag: 'SYNC',
            error: e,
            stackTrace: st,
          );
          await _handleJobFailure(job, failure);
          continue;
        }

        await result.fold(
          (error) async => _handleJobFailure(job, error),
          (success) async {
            await _queueRepository.markEntitySyncState(
              entityName: job.entityName,
              localId: success.localId,
              status: SyncStatus.synced,
              serverId: success.serverId,
              lastError: null,
            );
            await _queueRepository.markJobSuccess(jobId: job.jobId);
            await _opsLog.log(
              entityName: job.entityName,
              entityId: job.entityId,
              jobId: job.jobId,
              operation: SyncLogOperation.pushed,
              serverId: success.serverId,
            );
          },
        );
      }
    }
  }

  // ── Pull ────────────────────────────────────────────────────────────────────

  /// Downloads and merges server changes for every entity that declares a
  /// [SyncPullExecutor].
  ///
  /// **The half of this module that did not exist.** Until now the engine only
  /// pushed, so the local store held nothing but what this device had written —
  /// while `readme/sync.md` described a system whose every UI read came from it.
  ///
  /// Each entity is pulled independently and its cursor advanced independently:
  /// one entity's server error must not stall or, worse, skip past another's
  /// changes.
  Future<void> _processPullPhase({int pageLimit = 200, int maxPages = 50}) async {
    if (!_getIt.isRegistered<SyncPullExecutor>()) return;

    for (final executor in _getIt.getAll<SyncPullExecutor>()) {
      try {
        await _pullEntity(executor, pageLimit: pageLimit, maxPages: maxPages);
      } catch (e, st) {
        // One entity's failure leaves every other entity's pull intact — and
        // leaves its own cursor exactly where it was, so nothing is skipped.
        LogService.error(
          'Pull failed for "${executor.entityName}" — its cursor is unchanged, '
          'so the next cycle re-requests the same window.',
          tag: 'SYNC',
          error: e,
          stackTrace: st,
        );
        // **Written down, not only logged.** `LogService` output does not
        // survive the process, and a pull that has failed every cycle for a
        // week is otherwise indistinguishable from one that has nothing to do.
        // `sync_operations_log` is the module's existing durable record and it
        // already carries a `failed` operation; the push path has always used
        // it and the pull path never did.
        await _logQuietly(
          entityName: executor.entityName,
          entityId: '*',
          operation: SyncLogOperation.failed,
          errorCode: e.runtimeType.toString(),
          errorDetail: e.toString(),
        );
      }
    }
  }

  /// Records an operation without letting the recording become the failure.
  ///
  /// Used on the paths that are *already* handling an error: if writing the
  /// audit row throws too, the original problem is what matters and must not be
  /// replaced by a storage exception thrown while describing it.
  Future<void> _logQuietly({
    required String entityName,
    required String entityId,
    required SyncLogOperation operation,
    String? errorCode,
    String? errorDetail,
  }) async {
    try {
      await _opsLog.log(
        entityName: entityName,
        entityId: entityId,
        operation: operation,
        errorCode: errorCode,
        errorDetail: errorDetail,
      );
    } catch (e) {
      LogService.warning(
        'Could not record a $operation entry for "$entityName": $e',
        tag: 'SYNC',
      );
    }
  }

  Future<void> _pullEntity(
    SyncPullExecutor executor, {
    required int pageLimit,
    required int maxPages,
  }) async {
    final entityName = executor.entityName;
    var cursor = await _cursorStore.read(entityName);
    var pages = 0;

    while (pages < maxPages) {
      final result = await executor.pull(
        cursor: cursor,
        // Tombstones are the only way a delete reaches a device that already
        // holds the row.
        includeDeleted: true,
        limit: pageLimit,
      );

      final page = result.fold<SyncPullPage?>((failure) {
        LogService.debug(
          'Pull page failed for "$entityName" (${failure.runtimeType}) — '
          'keeping the cursor.',
          tag: 'SYNC',
        );
        return null;
      }, (page) => page);

      if (page == null) return;

      await _mergePulled(entityName, page.records);
      pages++;

      if (page.nextCursor != null) {
        // More to come in this run: page on with the server's own cursor.
        cursor = page.nextCursor!;
        await _cursorStore.write(entityName, cursor);
        continue;
      }

      // Caught up. The cursor becomes the server's clock, with no `after_id`:
      // the next cycle asks for everything written after this moment.
      await _cursorStore.write(
        entityName,
        SyncCursor(updatedSince: page.serverTime),
      );
      LogService.info(
        'Pull complete for "$entityName" — $pages page(s).',
        tag: 'SYNC',
      );
      return;
    }

    LogService.warning(
      'Pull for "$entityName" stopped at the $maxPages-page cap with more to '
      'come. The cursor is saved, so the next cycle resumes — but a backlog '
      'this size means the device has been offline long enough to be worth '
      'noticing.',
      tag: 'SYNC',
    );
  }

  /// Writes a page into the local store — **without touching anything the
  /// device has not sent yet.**
  ///
  /// ## A pending row is skipped, not merged
  ///
  /// It holds an edit the server has not seen, so the incoming copy is *older*
  /// by definition. Overwriting it would discard the user's work during a
  /// routine refresh, with no failure anywhere and nothing to notice.
  ///
  /// ## And so is a terminal one — `failed` and `conflicted`
  ///
  /// The guard used to ask only `isPending`, which covers the four `pending*`
  /// states and neither terminal one. So a row whose push had exhausted its
  /// retries, or whose 409 was waiting for a person, fell straight through and
  /// was replaced by the server's copy and stamped `synced`. The one remaining
  /// record of that edit was destroyed by a routine refresh, silently — not
  /// even counted in `skipped`.
  ///
  /// Both states are defined as *waiting for something*:
  ///
  /// - `conflicted` — "Awaits [SyncConflictResolver] or user action"
  ///   (`sync_status.dart`), and `ARCHITECTURE.md` §10 is explicit that a
  ///   conflict is **a durable local state with a screen, not a passing
  ///   event**: a field worker cannot resolve forty conflicts as they happen
  ///   and settles them from a list at the end of the day. A row overwritten
  ///   hours before that is a resolution nobody was offered.
  /// - `failed` — "Requires manual intervention or full re-bootstrap".
  ///
  /// `SyncConflictStrategy.manual` says it plainest: *"no automatic
  /// resolution"*. A pull that replaces the row **is** an automatic
  /// resolution, and the one strategy that exists to forbid choosing a side
  /// was the one silently choosing the server's.
  ///
  /// The predicate is therefore both existing halves of the state model —
  /// `isPending` (a write in flight) or `isTerminal` (a write that stopped and
  /// is owed an answer). Between them they cover every state except `synced`,
  /// which is the only one that means this device holds nothing the server has
  /// not seen. `isTerminal` had been defined since the enum was written and
  /// had never had a caller; this is it.
  ///
  /// Nor is a conflict manufactured here. The queued write is about to be
  /// pushed, and if the two sides really do disagree the server answers 409 —
  /// carrying `server_version`, `client_version` and the exact
  /// `conflict_fields`. Guessing at that shape locally would duplicate the
  /// resolution path with strictly worse information than the one that already
  /// exists.
  Future<void> _mergePulled(
    String entityName,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return;

    final incoming = <SyncEntityRecord>[];
    var skipped = 0;

    // Validate the page first, then read the local rows it touches **in one
    // query**. This used to be a `getRecordByLocalId` per record: 200 point
    // lookups for a full page, and up to 10,000 in a single first sync, each a
    // separate round trip across the platform channel while the sync lock is
    // held.
    final usable = <String, Map<String, dynamic>>{};
    for (final json in records) {
      final id = json['id'] as String?;
      if (id == null || id.isEmpty) {
        LogService.warning(
          'Pulled a "$entityName" record with no id — skipped. The server is '
          'not honouring the sync contract (SETUP.md §6).',
          tag: 'SYNC',
        );
        continue;
      }
      if (_epochOf(json['updated_at']) == null) {
        // Storing it would mean inventing an `updated_at`, and that column is
        // the local keyset ordering — a fabricated "now" silently promotes the
        // row to newest. Dropped and named, like a record with no id.
        LogService.warning(
          'Pulled "$entityName" record "$id" with an unreadable updated_at '
          '(${json['updated_at']}) — skipped rather than stored under a '
          'timestamp this device made up.',
          tag: 'SYNC',
        );
        continue;
      }
      usable[id] = json;
    }

    if (usable.isEmpty) return;

    final existing = await _entityStore.findByLocalIds(
      entityName: entityName,
      localIds: usable.keys.toList(),
    );

    for (final entry in usable.entries) {
      final id = entry.key;
      final json = entry.value;

      final local = existing[id];
      if (local != null &&
          (local.syncStatus.isPending || local.syncStatus.isTerminal)) {
        skipped++;
        continue;
      }

      incoming.add(
        SyncEntityRecord(
          localId: id,
          entityName: entityName,
          serverId: id,
          dataJson: jsonEncode(json),
          updatedAt: _epochOf(json['updated_at'])!,
          version: (json['version'] as int?) ?? 1,
          syncStatus: SyncStatus.synced,
          // A tombstone is a row, not an absence — it is how the delete
          // travels, and it must be stored as one.
          isDeleted: json['is_deleted'] == true,
          lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    if (incoming.isNotEmpty) {
      // One transaction per page: a half-applied page would leave the cursor
      // describing a state the store never reached.
      await _entityStore.upsertRecords(incoming);
    }
    if (skipped > 0) {
      LogService.info(
        'Kept $skipped local "$entityName" row(s) the server has not seen. '
        'Pending rows resolve on the next push; failed and conflicted ones '
        'wait for a person, and this refresh deliberately left them alone.',
        tag: 'SYNC',
      );
    }
  }

  /// Server timestamps arrive as ISO-8601 strings; the store keeps epoch ms.
  ///
  /// Returns `null` when the value is absent or unreadable — it does **not**
  /// substitute the device clock. `updated_at` is what orders every local read
  /// (`getRecordsAfter` pages on `updated_at DESC, local_id DESC`), so a
  /// fabricated "now" does not merely lose a timestamp: it stamps the row as
  /// the newest thing on the device and moves it to the top of a list it does
  /// not belong at the top of.
  ///
  /// The module already refuses to guess a server time — `NotesSyncPullExecutor`
  /// fails the whole page with 502 rather than fall back to the device clock,
  /// and says why. This is the same rule one level down, and the caller drops
  /// the record instead of storing a misordered one.
  static int? _epochOf(dynamic value) {
    if (value is int) return value;
    if (value is String) return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    return null;
  }

  // ── Files ───────────────────────────────────────────────────────────────────

  /// Sends the files the device owes the server.
  ///
  /// Resolved from the container rather than injected, so an app that registers
  /// no upload targets — which is every app until a feature declares one — pays
  /// nothing and this phase is a single `isRegistered` check.
  Future<void> _processFileUploads() async {
    if (!_getIt.isRegistered<AttachmentUploadManager>()) return;
    try {
      final sent = await _getIt<AttachmentUploadManager>().uploadPending();
      if (sent > 0) {
        LogService.info('Uploaded $sent attachment(s).', tag: 'SYNC');
      }
    } catch (e, st) {
      // A file failure must not abort the cycle: the row writes above already
      // succeeded, and losing their acknowledgement to an exception thrown by
      // an unrelated photograph would re-push every one of them next time.
      LogService.error(
        'Attachment upload phase failed — row sync is unaffected.',
        tag: 'SYNC',
        error: e,
        stackTrace: st,
      );
      // Durable, for the same reason the pull phase records its failures: a
      // phase that has been broken since install must not look like a phase
      // with nothing to do.
      await _logQuietly(
        entityName: 'attachments',
        entityId: '*',
        operation: SyncLogOperation.failed,
        errorCode: e.runtimeType.toString(),
        errorDetail: e.toString(),
      );
    }
  }

  // ── Failure handling ────────────────────────────────────────────────────────

  Future<void> _handleJobFailure(SyncQueueJob job, Failure error) async {
    if (error is ConflictFailure) {
      await _handleConflict(job, error);
      return;
    }

    final nextCount = job.retryCount + 1;
    final exceeded = nextCount >= job.maxRetries;
    final status = exceeded ? SyncStatus.failed : SyncStatus.pending;

    await _queueRepository.markEntitySyncState(
      entityName: job.entityName,
      localId: job.entityId,
      status: status,
      lastError: error.diagnosticMessage ?? '',
    );
    await _queueRepository.markJobRetry(
      jobId: job.jobId,
      retryCount: nextCount,
      nextRetryAt: _backoffPolicy.nextRetryAtMillis(
        retryCount: nextCount,
        baseDelaySeconds: 2,
        maxDelaySeconds: 600,
      ),
      lastError: error.diagnosticMessage ?? '',
    );

    await _opsLog.log(
      entityName: job.entityName,
      entityId: job.entityId,
      jobId: job.jobId,
      operation: exceeded ? SyncLogOperation.deadLetter : SyncLogOperation.retried,
      errorCode: error.runtimeType.toString(),
      errorDetail: error.diagnosticMessage,
    );
  }

  Future<void> _handleConflict(SyncQueueJob job, ConflictFailure conflict) async {
    LogService.warning(
      'HTTP 409 conflict for ${job.entityName}/${job.entityId}',
      tag: 'SYNC',
    );

    final contract = _resolveContract(job.entityName);
    final strategy = contract?.conflictStrategy ?? SyncConflictStrategy.serverWins;

    // Fetch the EXACT record that conflicted (by entityId), not just the
    // most-recently-updated record of this entity type.
    final localRecord = await _entityStore.getRecordByLocalId(
      entityName: job.entityName,
      localId: job.entityId,
    );

    if (localRecord == null) {
      await _queueRepository.markJobSuccess(jobId: job.jobId);
      return;
    }

    final resolution = _conflictResolver.resolve(
      localRecord: localRecord,
      conflict: conflict,
      job: job,
      strategy: strategy,
    );

    switch (resolution) {
      case ServerWinsResolution(:final serverRecord):
        await _entityStore.upsertRecord(serverRecord);
        await _queueRepository.markEntitySyncState(
          entityName: job.entityName,
          localId: job.entityId,
          status: SyncStatus.synced,
          lastError: null,
        );
        await _queueRepository.markJobSuccess(jobId: job.jobId);
        await _opsLog.log(
          entityName: job.entityName,
          entityId: job.entityId,
          jobId: job.jobId,
          operation: SyncLogOperation.conflictResolved,
          errorCode: 'server_wins',
        );

      case ClientWinsResolution(:final rebaseToVersion):
        // **Rebase, then retry.** Re-queuing the job untouched would send the
        // same stale base version the server just refused, so the retry earns
        // another 409, and the one after that, until `max_retries` marks the
        // job `failed`. A strategy named "the client wins" would end with the
        // client losing — five attempts later, and silently.
        //
        // Stamping the server's current version onto the payload leaves the
        // content alone and changes only what the write claims to be based on.
        // The optimistic check then passes and the local content is written.
        await _rebaseJobToVersion(job, rebaseToVersion);
        await _queueRepository.markJobRetry(
          jobId: job.jobId,
          retryCount: job.retryCount + 1,
          nextRetryAt: DateTime.now().millisecondsSinceEpoch + 500,
          lastError: 'conflict:client_wins_rebased_to_v$rebaseToVersion',
        );
        await _opsLog.log(
          entityName: job.entityName,
          entityId: job.entityId,
          jobId: job.jobId,
          operation: SyncLogOperation.conflictResolved,
          errorCode: 'client_wins',
        );

      case MergedResolution(:final mergedRecord):
        await _entityStore.upsertRecord(mergedRecord);
        await _queueRepository.markEntitySyncState(
          entityName: job.entityName,
          localId: job.entityId,
          status: SyncStatus.synced,
          lastError: null,
        );
        await _queueRepository.markJobSuccess(jobId: job.jobId);
        await _opsLog.log(
          entityName: job.entityName,
          entityId: job.entityId,
          jobId: job.jobId,
          operation: SyncLogOperation.conflictResolved,
          errorCode: 'merged',
        );

      case ManualResolutionRequired():
        await _queueRepository.markEntitySyncState(
          entityName: job.entityName,
          localId: job.entityId,
          status: SyncStatus.conflicted,
          lastError: 'manual_resolution_required',
        );
        // **The job has to stop being due, or it never stops.**
        //
        // This branch advanced nothing: not `retry_count`, not `next_retry_at`.
        // The row stayed immediately due, so the next cycle pushed it, got the
        // same 409, and landed here again — a full request per cycle, forever,
        // for a conflict that by definition is waiting for a person.
        // `retry_count < max_retries` could not bound it either, because the
        // count never moved.
        //
        // Retiring it to the ceiling is what "manual" means: the queue stops
        // acting, `SyncStatus.conflicted` holds the local row (the pull merge
        // protects it), and the job is kept so the resolution UI has the
        // payload to work from. `SyncConflictStrategy.manual` says it exactly —
        // "no automatic resolution" — and re-sending on a timer is automatic
        // resolution by exhaustion.
        await _queueRepository.markJobRetry(
          jobId: job.jobId,
          retryCount: job.maxRetries,
          nextRetryAt: DateTime.now().millisecondsSinceEpoch,
          lastError: 'manual_resolution_required',
        );
        await _opsLog.log(
          entityName: job.entityName,
          entityId: job.entityId,
          jobId: job.jobId,
          operation: SyncLogOperation.conflicted,
          errorCode: 'manual',
        );
    }
  }

  /// Stamps [version] onto the queued payload without touching its content.
  ///
  /// The version travels **inside** the payload rather than beside it, because
  /// that is where the executor reads it from when building the request body —
  /// see the `version` field on `updateNoteBodySchema` in `backend_template`.
  ///
  /// Failure here is logged and swallowed **on purpose, and only here**: the
  /// worst case is a retry that conflicts again and eventually dead-letters,
  /// which is exactly what happened before this method existed. Throwing would
  /// abort the whole sync cycle over one job.
  Future<void> _rebaseJobToVersion(SyncQueueJob job, int? version) async {
    if (version == null) return;
    try {
      final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;
      payload['version'] = version;
      await _queueRepository.updateJobPayloadAndVersion(
        jobId: job.jobId,
        payloadJson: jsonEncode(payload),
        // The *contract* version, not the entity version — two different
        // numbers that share a word. This one is unchanged by a rebase.
        contractVersion: job.contractVersion,
      );
    } catch (e, st) {
      LogService.error(
        'Could not rebase ${job.entityName}/${job.entityId} onto v$version — '
        'the retry will carry its old base version and conflict again.',
        tag: 'SYNC',
        error: e,
        stackTrace: st,
      );
    }
  }

  Map<String, SyncExecutor> _buildExecutorCache() {
    if (!_getIt.isRegistered<SyncExecutor>()) return const {};
    return {for (final e in _getIt.getAll<SyncExecutor>()) e.entityName: e};
  }

  SyncFeatureContractBase? _resolveContract(String entityName) {
    if (!_getIt.isRegistered<SyncFeatureContractBase>()) return null;
    try {
      final contracts = _getIt.getAll<SyncFeatureContractBase>();
      for (final c in contracts) {
        if (c.entityName == entityName) return c;
      }
    } catch (e) {
      // A fallback path logs — `catch (_) {}` is banned in this template, and
      // this site is why the ban matters here: swallowing means every conflict
      // for this entity silently falls back to serverWins, discarding the
      // user's local edit under a strategy nobody chose. That is data loss
      // with no symptom to search for.
      LogService.error(
        'Contract lookup failed for "$entityName" — falling back to serverWins, '
        'which DISCARDS the local change if a conflict follows.',
        tag: 'SYNC',
        error: e,
      );
    }
    return null;
  }
}
