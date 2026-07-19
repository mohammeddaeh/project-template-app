import 'sync_status.dart';

class SyncEntityRecord {
  const SyncEntityRecord({
    required this.localId,
    required this.entityName,
    required this.dataJson,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
    required this.isDeleted,
    this.serverId,
    this.lastSyncedAt,
    this.lastError,
  });

  final String localId;
  final String entityName;
  final String? serverId;
  final String dataJson;
  final int updatedAt;
  final int version;
  final SyncStatus syncStatus;
  final bool isDeleted;
  final int? lastSyncedAt;
  final String? lastError;

  SyncEntityRecord copyWith({
    String? localId,
    String? entityName,
    String? serverId,
    String? dataJson,
    int? updatedAt,
    int? version,
    SyncStatus? syncStatus,
    bool? isDeleted,
    int? lastSyncedAt,
    String? lastError,
  }) {
    return SyncEntityRecord(
      localId: localId ?? this.localId,
      entityName: entityName ?? this.entityName,
      serverId: serverId ?? this.serverId,
      dataJson: dataJson ?? this.dataJson,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError ?? this.lastError,
    );
  }
}
