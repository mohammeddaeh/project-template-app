import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:app_template/core/platform/logging/log_service.dart';

import '../automation/sync_feature_contract.dart';
import '../domain/sync_change_notifier.dart';
import '../domain/sync_entity_record.dart';
import '../domain/sync_entity_store.dart';
import '../domain/sync_status.dart';
import 'sync_database.dart';

class SqlSyncEntityStore implements SyncEntityStore {
  SqlSyncEntityStore(this._database, this._notifier);

  final SyncDatabase _database;
  final SyncChangeNotifier _notifier;

  @override
  Stream<void> watch(String entityName) => _notifier.watch(entityName);

  @override
  Future<void> upsertRecord(SyncEntityRecord record) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert('synced_entities', _toMap(record), conflictAlgorithm: ConflictAlgorithm.replace);
    });
    // After the commit, never before: a listener that refreshes on the
    // announcement would otherwise read the state that existed before it.
    _notifier.notify(record.entityName);
  }

  @override
  Future<void> upsertRecords(
    List<SyncEntityRecord> records, {
    bool notify = true,
  }) async {
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

    if (notify) {
      for (final entity in records.map((r) => r.entityName).toSet()) {
        _notifier.notify(entity);
      }
    }
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
  Future<List<SyncEntityRecord>> getRecordsAfter({
    required String entityName,
    required int limit,
    SyncPageCursor? cursor,
    bool includeDeleted = false,
  }) async {
    final db = await _database.database;

    final where = StringBuffer('entity_name = ?');
    final args = <Object?>[entityName];
    if (!includeDeleted) where.write(' AND is_deleted = 0');

    if (cursor != null) {
      // Strictly *after* the cursor in `(updated_at DESC, local_id DESC)` order.
      // The second clause is what makes rows sharing a millisecond resumable:
      // without it a page boundary inside such a group skips the rest of it.
      where.write(' AND (updated_at < ? OR (updated_at = ? AND local_id < ?))');
      args..add(cursor.updatedAt)..add(cursor.updatedAt)..add(cursor.localId);
    }

    final rows = await db.query(
      'synced_entities',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'updated_at DESC, local_id DESC',
      limit: limit,
    );

    return rows.map(_fromMap).toList();
  }

  @override
  Future<SyncTypedPage<T>> readTyped<T>({
    required SyncFeatureContract<T> contract,
    required int limit,
    SyncPageCursor? cursor,
    bool includeDeleted = false,
  }) async {
    final records = await getRecordsAfter(
      entityName: contract.entityName,
      limit: limit,
      cursor: cursor,
      includeDeleted: includeDeleted,
    );

    final parsed = <T>[];
    for (final record in records) {
      try {
        parsed.add(
          contract.fromJson(jsonDecode(record.dataJson) as Map<String, dynamic>),
        );
      } catch (e) {
        // Skipped, not fatal — one unreadable row must not blank a list. And
        // logged, because a store that silently drops rows is indistinguishable
        // from one that never had them.
        LogService.error(
          'Unreadable ${contract.entityName} row "${record.localId}" — skipped.',
          tag: 'SYNC',
          error: e,
        );
      }
    }

    return SyncTypedPage<T>(
      items: parsed,
      hasMore: records.length == limit,
      // From the last **record**, not the last parsed item: a row that failed
      // to parse still holds its place in the ordering, and a cursor that
      // skipped over it would re-serve it on every page from here on.
      nextCursor: records.isEmpty
          ? null
          : SyncPageCursor(
              updatedAt: records.last.updatedAt,
              localId: records.last.localId,
            ),
    );
  }

  @override
  Future<Map<String, SyncEntityRecord>> findByLocalIds({
    required String entityName,
    required List<String> localIds,
  }) async {
    if (localIds.isEmpty) return const {};

    final db = await _database.database;
    // Chunked because SQLite caps the number of bound variables (999 by
    // default) and a caller is free to hand over a whole page. The pull uses
    // 200, comfortably inside one chunk; the loop is here so a larger page
    // never turns into a `too many SQL variables` error at the worst moment.
    const chunkSize = 500;
    final found = <String, SyncEntityRecord>{};

    for (var start = 0; start < localIds.length; start += chunkSize) {
      final chunk = localIds.sublist(
        start,
        start + chunkSize > localIds.length ? localIds.length : start + chunkSize,
      );
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final rows = await db.query(
        'synced_entities',
        where: 'entity_name = ? AND local_id IN ($placeholders)',
        whereArgs: [entityName, ...chunk],
      );
      for (final row in rows) {
        final record = _fromMap(row);
        found[record.localId] = record;
      }
    }

    return found;
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
