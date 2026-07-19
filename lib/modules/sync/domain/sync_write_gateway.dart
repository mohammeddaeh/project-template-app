import 'sync_status.dart';

class SyncWriteCommand {
  const SyncWriteCommand({
    required this.entityName,
    required this.localId,
    required this.serverId,
    required this.dataJson,
    required this.updatedAt,
    required this.version,
    required this.isDeleted,
    required this.jobType,
    required this.jobPayloadJson,
    required this.contractVersion,
    this.enqueue = true,
    this.jobIdempotencyKey,
    this.maxRetries = 5,
  });

  final String entityName;
  final String localId;
  final String? serverId;
  final String dataJson;
  final int updatedAt;
  final int version;
  final bool isDeleted;
  final SyncJobType jobType;
  final String jobPayloadJson;
  final int contractVersion;
  final bool enqueue;
  final String? jobIdempotencyKey;
  final int maxRetries;
}

abstract class SyncWriteGateway {
  Future<void> write(SyncWriteCommand command);
}
