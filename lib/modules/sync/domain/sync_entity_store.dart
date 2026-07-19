import 'sync_entity_record.dart';

abstract class SyncEntityStore {
  Future<void> upsertRecord(SyncEntityRecord record);
  Future<void> upsertRecords(List<SyncEntityRecord> records);
  Future<List<SyncEntityRecord>> getRecordsByEntity({
    required String entityName,
    required int page,
    required int limit,
    bool includeDeleted = false,
  });

  /// Returns the single record matching [entityName] + [localId], or null.
  /// Used by conflict resolution to fetch the EXACT conflicting record.
  Future<SyncEntityRecord?> getRecordByLocalId({
    required String entityName,
    required String localId,
  });
  Future<int> countRecordsByEntity({
    required String entityName,
    bool includeDeleted = false,
  });
}
