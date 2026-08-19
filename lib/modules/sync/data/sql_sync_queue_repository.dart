import 'package:app_template/core/platform/logging/log_service.dart';

import '../domain/sync_change_notifier.dart';
import '../domain/sync_queue_job.dart';
import '../domain/sync_queue_repository.dart';
import '../domain/sync_status.dart';
import 'sync_database.dart';

class SqlSyncQueueRepository implements SyncQueueRepository {
  SqlSyncQueueRepository(this._database, this._notifier);

  final SyncDatabase _database;
  final SyncChangeNotifier _notifier;

  @override
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
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final iKey = idempotencyKey ?? '${entityName}_${entityId}_${type.raw}_$now';

    await db.transaction((txn) async {
      final existing = await txn.query(
        'sync_queue',
        where: 'entity_name = ? AND entity_id = ?',
        whereArgs: [entityName, entityId],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final existingType = SyncJobType.fromRaw(
          existing.first['type'] as String,
        );
        final mergedType = _mergedType(
          existingType: existingType,
          incomingType: type,
        );
        await txn.update(
          'sync_queue',
          {
            'job_id': jobId,
            'type': mergedType.raw,
            'payload_json': payloadJson,
            'contract_version': contractVersion,
            'idempotency_key': iKey,
            'priority': priority,
            'retry_count': 0,
            'next_retry_at': now,
            'last_error': null,
          },
          where: 'job_id = ?',
          whereArgs: [existing.first['job_id']],
        );
        return;
      }

      await txn.insert('sync_queue', {
        'job_id': jobId,
        'type': type.raw,
        'entity_name': entityName,
        'entity_id': entityId,
        'payload_json': payloadJson,
        'contract_version': contractVersion,
        'idempotency_key': iKey,
        'priority': priority,
        'retry_count': 0,
        'max_retries': maxRetries,
        'next_retry_at': now,
        'created_at': now,
        'last_error': null,
      });
    });
  }

  @override
  Future<List<SyncQueueJob>> getDueJobs({
    required int nowMs,
    required int limit,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'sync_queue',
      // `retry_count < max_retries` is what ends a job's life.
      //
      // Without it the only filter was the back-off clock, so a write the
      // server will never accept — a 422 whose payload is wrong, an entity
      // whose executor was deleted — came due again every ten minutes for as
      // long as the app existed. `_handleJobFailure` already computed
      // `exceeded`, marked the row `failed` and wrote a `deadLetter` line to
      // the operations log; the queue simply never read any of it back.
      //
      // The row is **kept, not deleted**: it holds the payload and the last
      // error, which is what makes a dead job diagnosable. It is excluded from
      // execution, not from existence — `max_retries` per row (default 5,
      // schema v3) stays the single source of truth, and no column changes.
      where: 'next_retry_at <= ? AND retry_count < max_retries',
      whereArgs: [nowMs],
      orderBy: 'priority ASC, next_retry_at ASC, created_at ASC',
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<SyncQueueJob>> getAllJobs({int limit = 500}) async {
    final db = await _database.database;
    final rows = await db.query(
      'sync_queue',
      orderBy: 'priority ASC, created_at ASC',
      limit: limit,
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<void> updateJobPayloadAndVersion({
    required String jobId,
    required String payloadJson,
    required int contractVersion,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'sync_queue',
        {'payload_json': payloadJson, 'contract_version': contractVersion},
        where: 'job_id = ?',
        whereArgs: [jobId],
      );
    });
  }

  @override
  Future<void> markJobSuccess({required String jobId}) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('sync_queue', where: 'job_id = ?', whereArgs: [jobId]);
    });
  }

  @override
  Future<void> markJobRetry({
    required String jobId,
    required int retryCount,
    required int nextRetryAt,
    required String? lastError,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'sync_queue',
        {
          'retry_count': retryCount,
          'next_retry_at': nextRetryAt,
          'last_error': lastError,
        },
        where: 'job_id = ?',
        whereArgs: [jobId],
      );
    });
  }

  @override
  Future<void> markEntitySyncState({
    required String entityName,
    required String localId,
    required SyncStatus status,
    String? serverId,
    String? lastError,
  }) async {
    final db = await _database.database;
    final affected = await db.transaction((txn) async {
      return txn.update(
        'synced_entities',
        {
          'sync_status': status.raw,
          'server_id': ?serverId,
          if (status == SyncStatus.synced)
            'last_synced_at': DateTime.now().millisecondsSinceEpoch,
          'last_error': lastError,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'entity_name = ? AND local_id = ?',
        whereArgs: [entityName, localId],
      );
    });

    // An UPDATE that matched nothing is not a no-op, it is a lost state
    // transition: the engine believes the row is now `synced` (or `failed`, or
    // `conflicted`) and the store still says whatever it said before. Silent,
    // because SQL is perfectly happy to change zero rows.
    //
    // It is reported rather than thrown: the push already succeeded or failed
    // on the server, and aborting the cycle here would re-send work that landed.
    // What matters is that the divergence stops being invisible.
    if (affected == 0) {
      LogService.error(
        'Sync state "${status.raw}" for $entityName/$localId matched no local '
        'row — the entity and its queue have diverged. The write was accepted '
        'remotely; nothing local records it.',
        tag: 'SYNC',
      );
    }

    // A push finished — succeeded, failed, or conflicted. The row's badge
    // changes even though its content did not, and a list showing "pending"
    // next to an item that synced ten minutes ago is a list nobody trusts.
    _notifier.notify(entityName);
  }

  @override
  Future<int> countPendingJobs() async {
    final db = await _database.database;
    // **Counts what is still going to be attempted, not what is still stored.**
    //
    // A dead-lettered row stays in the table — that is deliberate, it holds the
    // payload and the last error. But it is never selected by `getDueJobs`
    // again, so counting it told the user there was work in flight that nothing
    // would ever act on: a pending badge that could not reach zero, on an app
    // that was in fact idle. The predicate matches `getDueJobs`.
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM sync_queue WHERE retry_count < max_retries',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  SyncJobType _mergedType({
    required SyncJobType existingType,
    required SyncJobType incomingType,
  }) {
    if (incomingType == SyncJobType.delete) return SyncJobType.delete;
    if (existingType == SyncJobType.create &&
        incomingType == SyncJobType.update) {
      return SyncJobType.create;
    }
    return incomingType;
  }

  SyncQueueJob _fromMap(Map<String, dynamic> map) {
    return SyncQueueJob(
      jobId: map['job_id'] as String,
      type: SyncJobType.fromRaw(map['type'] as String),
      entityName: map['entity_name'] as String,
      entityId: map['entity_id'] as String,
      payloadJson: map['payload_json'] as String,
      contractVersion: map['contract_version'] as int? ?? 1,
      retryCount: map['retry_count'] as int,
      maxRetries: map['max_retries'] as int,
      nextRetryAt: map['next_retry_at'] as int,
      createdAt: map['created_at'] as int,
      priority: map['priority'] as int? ?? 10,
      idempotencyKey: map['idempotency_key'] as String?,
      lastError: map['last_error'] as String?,
    );
  }
}
