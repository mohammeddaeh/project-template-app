import 'package:sqflite/sqflite.dart';

import '../domain/sync_entity_record.dart';
import '../domain/sync_entity_store.dart';
import '../domain/sync_status.dart';
import 'sync_database.dart';

class SqlSyncEntityStore implements SyncEntityStore {
  SqlSyncEntityStore(this._database);

  final SyncDatabase _database;

  @override
  Future<void> upsertRecord(SyncEntityRecord record) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert('synced_entities', _toMap(record), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> upsertRecords(List<SyncEntityRecord> records) async {
    if (records.isEmpty) return;
    final db = await _database.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final record in records) {
        batch.insert(
          'synced_entities',
          _toMap(record),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<List<SyncEntityRecord>> getRecordsByEntity({
    required String entityName,
    required int page,
    required int limit,
    bool includeDeleted = false,
  }) async {
    final db = await _database.database;
    final safePage = page < 1 ? 1 : page;
    final offset = (safePage - 1) * limit;

    final rows = await db.query(
      'synced_entities',
      where: includeDeleted
          ? 'entity_name = ?'
          : 'entity_name = ? AND is_deleted = 0',
      whereArgs: [entityName],
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(_fromMap).toList();
  }

  @override
  Future<SyncEntityRecord?> getRecordByLocalId({
    required String entityName,
    required String localId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'synced_entities',
      where: 'entity_name = ? AND local_id = ?',
      whereArgs: [entityName, localId],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  @override
  Future<int> countRecordsByEntity({
    required String entityName,
    bool includeDeleted = false,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      includeDeleted
          ? 'SELECT COUNT(*) AS count FROM synced_entities WHERE entity_name = ?'
          : 'SELECT COUNT(*) AS count FROM synced_entities WHERE entity_name = ? AND is_deleted = 0',
      [entityName],
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  Map<String, dynamic> _toMap(SyncEntityRecord record) {
    return {
      'local_id': record.localId,
      'entity_name': record.entityName,
      'server_id': record.serverId,
      'data_json': record.dataJson,
      'updated_at': record.updatedAt,
      'version': record.version,
      'sync_status': record.syncStatus.raw,
      'is_deleted': record.isDeleted ? 1 : 0,
      'last_synced_at': record.lastSyncedAt,
      'last_error': record.lastError,
    };
  }

  SyncEntityRecord _fromMap(Map<String, dynamic> map) {
    return SyncEntityRecord(
      localId: map['local_id'] as String,
      entityName: map['entity_name'] as String,
      serverId: map['server_id'] as String?,
      dataJson: map['data_json'] as String,
      updatedAt: map['updated_at'] as int,
      version: map['version'] as int,
      syncStatus: SyncStatus.fromRaw(map['sync_status'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
      lastSyncedAt: map['last_synced_at'] as int?,
      lastError: map['last_error'] as String?,
    );
  }
}
