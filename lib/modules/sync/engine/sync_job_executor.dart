import 'package:dartz/dartz.dart';
import 'package:app_template/core/foundation/errors/failure.dart';

import '../domain/sync_queue_job.dart';

typedef JobExecutor = Future<Either<Failure, SyncExecutionResult>> Function(
  SyncQueueJob job,
);

class SyncExecutionResult {
  const SyncExecutionResult({
    required this.localId,
    this.serverId,
  });

  final String localId;
  final String? serverId;
}

abstract class SyncExecutor {
  String get entityName;
  Set<int> get supportedContractVersions;

  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  );
}
