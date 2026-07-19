import '../domain/sync_queue_job.dart';
import '../domain/sync_queue_repository.dart';
import '../domain/sync_status.dart';
import 'sync_database.dart';

class SqlSyncQueueRepository implements SyncQueueRepository {
  SqlSyncQueueRepository(this._database);

  final SyncDatabase _database;

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
      where: 'next_retry_at <= ?',
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
    await db.transaction((txn) async {
      await txn.update(
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
  }

  @override
  Future<int> countPendingJobs() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM sync_queue',
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
