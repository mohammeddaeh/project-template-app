import 'sync_status.dart';

class SyncQueueJob {
  const SyncQueueJob({
    required this.jobId,
    required this.type,
    required this.entityName,
    required this.entityId,
    required this.payloadJson,
    required this.contractVersion,
    required this.retryCount,
    required this.maxRetries,
    required this.nextRetryAt,
    required this.createdAt,
    required this.priority,
    this.idempotencyKey,
    this.lastError,
  });

  final String jobId;
  final SyncJobType type;
  final String entityName;
  final String entityId;
  final String payloadJson;
  final int contractVersion;
  final int retryCount;
  final int maxRetries;
  final int nextRetryAt;
  final int createdAt;

  /// Priority level: lower = processed first.
  /// 10 = entity CRUD, 50 = relation changes, 90 = file uploads.
  final int priority;

  /// Stable idempotency key sent as [Idempotency-Key] HTTP header.
  /// Derived from entityName + entityId + type + createdAt at insert time.
  /// MUST remain unchanged across all retry attempts for the same write intent.
  final String? idempotencyKey;

  final String? lastError;

  /// Builds a deterministic idempotency key from job identity fields.
  /// Returns [idempotencyKey] if already set, otherwise derives it.
  String get effectiveIdempotencyKey =>
      idempotencyKey ??
      '${entityName}_${entityId}_${type.raw}_$createdAt';
}
