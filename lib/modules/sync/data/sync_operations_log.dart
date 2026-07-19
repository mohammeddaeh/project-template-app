
import 'sync_database.dart';

/// All recognized operation types recorded in [sync_operations_log].
enum SyncLogOperation {
  enqueued,
  pushed,
  pulled,
  conflicted,
  conflictResolved,
  retried,
  failed,
  deadLetter,
  deleted,
}

/// Append-only audit log for every entity sync lifecycle event.
///
/// Backed by the `sync_operations_log` SQLite table (created in [SyncDatabase]).
///
/// ## Purpose
/// - Post-mortem debugging of data loss / duplication
/// - Audit trail for compliance use-cases
/// - Developer tooling (accessible via SETUP.md debug queries)
///
/// ## Rules
/// - Never delete rows programmatically (except via retention policy trim).
/// - `payloadSnapshot` stores a truncated copy (max 2 KB) for debugging.
/// - Never log personally identifiable data in `errorDetail` or `payloadSnapshot`.
class SyncOperationsLog {
  SyncOperationsLog(this._database);

  final SyncDatabase _database;

  static const int _maxPayloadSnapshotLength = 2048;
  static const int _maxRetainedRows = 10000;

  Future<void> log({
    required String entityName,
    required String entityId,
    required SyncLogOperation operation,
    String? jobId,
    String? serverId,
    String? errorCode,
    String? errorDetail,
    String? payloadSnapshot,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = payloadSnapshot != null
        ? payloadSnapshot.length > _maxPayloadSnapshotLength
            ? payloadSnapshot.substring(0, _maxPayloadSnapshotLength)
            : payloadSnapshot
        : null;

    await db.insert('sync_operations_log', {
      'entity_name': entityName,
      'entity_id': entityId,
      'job_id': jobId,
      'operation': operation.name,
      'occurred_at': now,
      'server_id': serverId,
      'error_code': errorCode,
      'error_detail': errorDetail,
      'payload_snapshot': snapshot,
    });
  }

  /// Returns the last [limit] operations for a given entity instance.
  Future<List<Map<String, dynamic>>> getLogsForEntity({
    required String entityName,
    required String entityId,
    int limit = 50,
  }) async {
    final db = await _database.database;
    return db.query(
      'sync_operations_log',
      where: 'entity_name = ? AND entity_id = ?',
      whereArgs: [entityName, entityId],
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
  }

  /// Returns the last [limit] operations across all entities (for debug panel).
  Future<List<Map<String, dynamic>>> getRecentLogs({int limit = 100}) async {
    final db = await _database.database;
    return db.query(
      'sync_operations_log',
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
  }

  /// Trims the log to the newest [_maxRetainedRows] rows.
  /// Call periodically from [SyncEngine] (e.g., after every 50 sync cycles).
  Future<void> trim() async {
    final db = await _database.database;
    await db.execute('''
      DELETE FROM sync_operations_log
      WHERE id NOT IN (
        SELECT id FROM sync_operations_log
        ORDER BY occurred_at DESC
        LIMIT $_maxRetainedRows
      )
    ''');
  }
}
