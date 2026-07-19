import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../config/sync_mode.dart';
import '../config/sync_settings_store.dart';
import '../domain/sync_status.dart';
import '../domain/sync_write_gateway.dart';
import '../validation/sync_contract_validator.dart';
import 'sync_database.dart';

class SqlSyncWriteGateway implements SyncWriteGateway {
  SqlSyncWriteGateway(
    this._database,
    this._settingsStore,
    this._uuid,
    this._contractValidator,
  );

  final SyncDatabase _database;
  final SyncSettingsStore _settingsStore;
  final Uuid _uuid;
  final SyncContractValidator _contractValidator;

  @override
  Future<void> write(SyncWriteCommand command) async {
    final db = await _database.database;
    final settings = await _settingsStore.getSettings();
    final now = DateTime.now().millisecondsSinceEpoch;
    final shouldQueue =
        command.enqueue && settings.mode == SyncMode.active && settings.syncEnabled;

    if (shouldQueue) {
      _contractValidator.validateQueuePayload(
        entityName: command.entityName,
        payloadJson: command.jobPayloadJson,
        contractVersion: command.contractVersion,
      );
    }

    await db.transaction((txn) async {
      await txn.insert(
        'synced_entities',
        {
          'local_id': command.localId,
          'entity_name': command.entityName,
          'server_id': command.serverId,
          'data_json': command.dataJson,
          'updated_at': command.updatedAt,
          'version': command.version,
          'sync_status': shouldQueue
              ? _pendingStatus(command.jobType).raw
              : SyncStatus.synced.raw,
          'is_deleted': command.isDeleted ? 1 : 0,
          'last_error': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (!shouldQueue) {
        return;
      }

      final existing = await txn.query(
        'sync_queue',
        where: 'entity_name = ? AND entity_id = ?',
        whereArgs: [command.entityName, command.localId],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      final mergedType = existing.isEmpty
          ? command.jobType
          : _mergeType(
              existingType: SyncJobType.fromRaw(existing.first['type'] as String),
              incomingType: command.jobType,
            );

      final jobId = command.jobIdempotencyKey ?? _uuid.v4();
      if (existing.isNotEmpty) {
        await txn.update(
          'sync_queue',
          {
            'job_id': jobId,
            'type': mergedType.raw,
            'payload_json': command.jobPayloadJson,
            'contract_version': command.contractVersion,
            'retry_count': 0,
            'max_retries': command.maxRetries,
            'next_retry_at': now,
            'last_error': null,
          },
          where: 'job_id = ?',
          whereArgs: [existing.first['job_id']],
        );
      } else {
        await txn.insert('sync_queue', {
          'job_id': jobId,
          'type': mergedType.raw,
          'entity_name': command.entityName,
          'entity_id': command.localId,
          'payload_json': command.jobPayloadJson,
          'contract_version': command.contractVersion,
          'retry_count': 0,
          'max_retries': command.maxRetries,
          'next_retry_at': now,
          'created_at': now,
          'last_error': null,
        });
      }
    });
  }

  SyncStatus _pendingStatus(SyncJobType type) => switch (type) {
        SyncJobType.create => SyncStatus.pendingCreate,
        SyncJobType.update => SyncStatus.pendingUpdate,
        SyncJobType.delete => SyncStatus.pendingDelete,
      };

  SyncJobType _mergeType({
    required SyncJobType existingType,
    required SyncJobType incomingType,
  }) {
    if (incomingType == SyncJobType.delete) return SyncJobType.delete;
    if (existingType == SyncJobType.create && incomingType == SyncJobType.update) {
      return SyncJobType.create;
    }
    return incomingType;
  }
}
