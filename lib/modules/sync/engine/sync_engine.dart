import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:get_it/get_it.dart';

import '../automation/sync_feature_contract.dart';
import '../config/sync_mode.dart';
import '../config/sync_settings_store.dart';
import '../data/sync_operations_log.dart';
import '../domain/sync_entity_store.dart';
import '../domain/sync_queue_repository.dart';
import '../domain/sync_status.dart';
import '../integration/sync_lock.dart';
import 'sync_backoff_policy.dart';
import 'sync_conflict_resolver.dart';
import 'sync_job_executor.dart';
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

  static int _cycleCount = 0;

  /// Full sync cycle: acquire lock → push queue → release lock.
  Future<void> runPendingJobs({int batchSize = 30}) async {
    final settings = await _settingsStore.getSettings();
    if (settings.mode != SyncMode.active || !settings.syncEnabled) return;

    final acquired = await _syncLock.tryAcquire();
    if (!acquired) {
      LogService.debug('SyncEngine skipped — lock held.', tag: 'SYNC');
      return;
    }

    try {
      await _processPushQueue(batchSize: batchSize);
    } catch (e, st) {
      LogService.error('SyncEngine failed', tag: 'SYNC', error: e, stackTrace: st);
    } finally {
      await _syncLock.release();
      _cycleCount++;
      if (_cycleCount % 50 == 0) {
        await _opsLog.trim();
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

        final result = await executor.execute(job, effectiveContractVersion);
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

  Future<void> _handleJobFailure(dynamic job, Failure error) async {
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

  Future<void> _handleConflict(dynamic job, ConflictFailure conflict) async {
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

      case ClientWinsResolution():
        // Re-queue with force flag — mark retry with minimal delay.
        await _queueRepository.markJobRetry(
          jobId: job.jobId,
          retryCount: job.retryCount + 1,
          nextRetryAt: DateTime.now().millisecondsSinceEpoch + 500,
          lastError: 'conflict:client_wins_retry',
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
        await _opsLog.log(
          entityName: job.entityName,
          entityId: job.entityId,
          jobId: job.jobId,
          operation: SyncLogOperation.conflicted,
          errorCode: 'manual',
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
    } catch (_) {}
    return null;
  }
}
