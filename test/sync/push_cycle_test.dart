import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/Features/notes/data/datasources/notes_api_service.dart';
import 'package:app_template/Features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:app_template/Features/notes/data/dtos/note_request_dto.dart';
import 'package:app_template/Features/notes/data/models/note_model.dart';
import 'package:app_template/Features/notes/data/sync/notes_sync_executor.dart';
import 'package:app_template/core/foundation/contracts/api_response.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/sync/automation/sync_feature_contract.dart';
import 'package:app_template/modules/sync/config/sync_mode.dart';
import 'package:app_template/modules/sync/config/sync_settings.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/data/sync_cursor_store.dart';
import 'package:app_template/modules/sync/data/sync_database.dart';
import 'package:app_template/modules/sync/data/sync_operations_log.dart';
import 'package:app_template/modules/sync/domain/sync_entity_record.dart';
import 'package:app_template/modules/sync/domain/sync_entity_store.dart';
import 'package:app_template/modules/sync/domain/sync_queue_job.dart';
import 'package:app_template/modules/sync/domain/sync_queue_repository.dart';
import 'package:app_template/modules/sync/domain/sync_status.dart';
import 'package:app_template/modules/sync/engine/sync_backoff_policy.dart';
import 'package:app_template/modules/sync/engine/sync_conflict_resolver.dart';
import 'package:app_template/modules/sync/engine/sync_engine.dart';
import 'package:app_template/modules/sync/engine/sync_job_executor.dart';
import 'package:app_template/modules/sync/integration/sync_lock.dart';
import 'package:app_template/modules/sync/validation/sync_contract_migrator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validator.dart';

/// Drives the **real** `SyncEngine.runPendingJobs` push phase.
///
/// ## The three defects this file pins
///
/// * **S9-1** — `executor.execute` sat outside any `try`. A throw escaped the
///   job loop, the push phase, and the pull and file phases with it, and left
///   the job with no `retry_count` and no `next_retry_at`: permanently due,
///   permanently first, blocking everything behind it.
/// * **S9-2** — every non-2xx arrives as a thrown `DioException`, so a real
///   HTTP 409 never reached `ConflictFailure`. The conflict resolver, its five
///   strategies and the rebase logic were unreachable code.
/// * **S9-3** — `getDueJobs` filtered on the back-off clock alone, so a write
///   the server will never accept came due again forever.
///
/// ## No sqflite
///
/// `SyncQueueRepository` and `SyncEntityStore` are interfaces, and
/// `SyncOperationsLog` is subclassable — so the engine runs against in-memory
/// doubles with no database, no platform channel and no new dependency. The
/// pull and file phases stay out of the way on their own: both open with an
/// `isRegistered` check, and this container registers neither.
void main() {
  late GetIt di;
  late _RecordingQueue queue;
  late _MemoryEntityStore entities;

  setUp(() {
    LogService.setDelegate(const _SilentLog());
    di = GetIt.asNewInstance()..enableRegisteringMultipleInstancesOfOneType();
    di.registerSingleton<SyncFeatureContractBase>(const _NotesContract());
    queue = _RecordingQueue();
    entities = _MemoryEntityStore();
  });

  tearDown(() async {
    LogService.setDelegate(const _SilentLog());
    await di.reset();
  });

  SyncEngine buildEngine(SyncExecutor executor, {SyncOperationsLog? opsLog}) {
    di.registerSingleton<SyncExecutor>(executor);
    final migrator = SyncContractMigrator(di);
    final settings = _FixedSettings();
    return SyncEngine(
      settings,
      queue,
      entities,
      SyncBackoffPolicy(),
      di,
      migrator,
      SyncContractValidator(di, queue, migrator),
      SyncConflictResolver(),
      SyncLock(_MemoryStorage()),
      opsLog ?? _SilentOpsLog(),
      SyncCursorStore(SyncDatabase()),
    );
  }

  SyncQueueJob job(String id, {int retryCount = 0, int maxRetries = 5}) =>
      SyncQueueJob(
        jobId: 'job-$id',
        type: SyncJobType.update,
        entityName: 'notes',
        entityId: id,
        payloadJson: jsonEncode({'id': id, 'title': 'T', 'version': 1}),
        contractVersion: 1,
        retryCount: retryCount,
        maxRetries: maxRetries,
        nextRetryAt: 0,
        createdAt: 0,
        priority: 10,
      );

  // ── Test A ─────────────────────────────────────────────────────────────────

  test('A — a throwing executor fails the job, not the cycle', () async {
    queue.seed([job('n1')]);
    final engine = buildEngine(_ThrowingExecutor(Exception('boom')));

    await engine.runPendingJobs();

    expect(
      queue.retries,
      hasLength(1),
      reason: 'The throw bypassed _handleJobFailure — S9-1 is back.',
    );
    expect(queue.retries.single.retryCount, 1);
    expect(
      queue.retries.single.nextRetryAt,
      greaterThan(DateTime.now().millisecondsSinceEpoch),
      reason: 'Back-off was not applied, so the job stays immediately due.',
    );
    expect(queue.successes, isEmpty);
    // The cycle completed rather than aborting: the lock was released, which
    // only happens through the `finally` at the end of a full run.
    expect(queue.pollCount, greaterThanOrEqualTo(1));
  });

  // ── Test B ─────────────────────────────────────────────────────────────────

  test('B — a real HTTP 409 reaches the conflict resolver', () async {
    // The genuine chain: a real DioException carrying the server's envelope,
    // through the real NotesSyncExecutor, into the real engine.
    entities.put(
      SyncEntityRecord(
        localId: 'n1',
        entityName: 'notes',
        serverId: 'n1',
        dataJson: jsonEncode({'id': 'n1', 'title': 'mine', 'version': 1}),
        updatedAt: 1,
        version: 1,
        syncStatus: SyncStatus.pending,
        isDeleted: false,
      ),
    );
    queue.seed([job('n1')]);

    final engine = buildEngine(
      NotesSyncExecutor(
        _ThrowingDataSource(
          _dioError(409, {
            'status': false,
            'message': 'conflict',
            // Nested under `data` — the shape `notes.int.test.ts` asserts.
            'data': {
              'server_version': {'id': 'n1', 'title': 'theirs', 'version': 7},
              'client_version': {'id': 'n1', 'title': 'mine', 'version': 1},
              'conflict_fields': ['title'],
            },
          }),
        ),
      ),
    );

    await engine.runPendingJobs();

    // serverWins is the contract's default strategy: the resolver ran, took the
    // server's row, and closed the job. None of that is reachable unless the
    // 409 became a ConflictFailure.
    expect(
      queue.successes,
      contains('job-n1'),
      reason: 'The 409 never reached _handleConflict — S9-2 is back.',
    );
    expect(entities.upserted, hasLength(1));
    expect(
      jsonDecode(entities.upserted.single.dataJson)['title'],
      'theirs',
      reason: 'SyncConflictResolver.serverWins did not apply.',
    );
    expect(
      queue.states.last.status,
      SyncStatus.synced,
      reason: 'A resolved conflict must not be left pending.',
    );
  });

  // ── Test C ─────────────────────────────────────────────────────────────────

  test('C — HTTP 422 is a failure, keeps the job, and backs off', () async {
    queue.seed([job('n1')]);
    final engine = buildEngine(
      NotesSyncExecutor(
        _ThrowingDataSource(
          _dioError(422, {'status': false, 'message': 'title required'}),
        ),
      ),
    );

    await engine.runPendingJobs();

    expect(queue.successes, isEmpty, reason: '422 must never look like a write that landed.');
    expect(queue.retries, hasLength(1));
    expect(queue.retries.single.retryCount, 1);
    expect(queue.deleted, isEmpty, reason: 'The job must survive to be diagnosable.');
  });

  // ── Test D ─────────────────────────────────────────────────────────────────

  test('D — HTTP 500 and a timeout each fail one job, not the cycle', () async {
    for (final error in [
      _dioError(500, {'status': false, 'message': 'server error'}),
      DioException(
        requestOptions: RequestOptions(path: '/notes/n1'),
        type: DioExceptionType.connectionTimeout,
      ),
    ]) {
      queue = _RecordingQueue()..seed([job('n1'), job('n2')]);
      entities = _MemoryEntityStore();
      await di.reset();
      di
        ..enableRegisteringMultipleInstancesOfOneType()
        ..registerSingleton<SyncFeatureContractBase>(const _NotesContract());

      final engine = buildEngine(
        NotesSyncExecutor(_ThrowingDataSource(error)),
      );
      await engine.runPendingJobs();

      expect(queue.successes, isEmpty);
      expect(
        queue.retries.map((r) => r.jobId),
        containsAll(<String>['job-n1', 'job-n2']),
        reason: 'One failure stopped the queue — S9-1 is back for ${error.type}.',
      );
      for (final retry in queue.retries) {
        expect(
          retry.nextRetryAt,
          greaterThan(DateTime.now().millisecondsSinceEpoch),
        );
      }
    }
  });

  // ── Test E ─────────────────────────────────────────────────────────────────

  test('E — the last allowed attempt marks the entity failed and dead-letters',
      () async {
    // maxRetries = 1, so the first failure exhausts the budget. The engine's
    // half of S9-3: it stops calling the row retryable and records the
    // dead-letter. The SQL half — `retry_count < max_retries` in getDueJobs —
    // is asserted separately below.
    queue.seed([job('n1', retryCount: 0, maxRetries: 1)]);
    final engine = buildEngine(_ThrowingExecutor(Exception('permanent')));

    await engine.runPendingJobs();

    expect(queue.states.single.status, SyncStatus.failed);
    expect(queue.retries.single.retryCount, 1);
  });

  test('E — a job at its retry ceiling is no longer due', () async {
    // The contract `getDueJobs` must honour, exercised against an
    // implementation of it. The shipped SQL applies the same predicate
    // (`retry_count < max_retries`); executing that statement needs sqflite,
    // which this suite deliberately does not pull in.
    queue.seed([
      job('n1', retryCount: 5, maxRetries: 5), // exhausted
      job('n2', retryCount: 0, maxRetries: 5), // still eligible
    ]);
    final engine = buildEngine(_ThrowingExecutor(Exception('boom')));

    await engine.runPendingJobs();

    expect(
      queue.retries.map((r) => r.jobId),
      ['job-n2'],
      reason: 'An exhausted job was executed again — S9-3 is back.',
    );
  });

  // ── Test F ─────────────────────────────────────────────────────────────────

  test('H — two overlapping triggers produce one cycle, not two', () async {
    // `SyncLock` is persisted, and persisting it costs an `await` between the
    // read and the write. Three independent triggers — the periodic timer, the
    // connectivity listener, a manual tap — can enter that window together and
    // both come out holding the lock, which is exactly what it exists to
    // prevent. The in-isolate guard closes it: check and set with nothing
    // awaited in between.
    queue.seed([job('n1'), job('n2')]);
    final executor = _CountingExecutor();
    final engine = buildEngine(executor);

    await Future.wait([
      engine.runPendingJobs(),
      engine.runPendingJobs(),
      engine.runPendingJobs(),
    ]);

    expect(
      executor.calls,
      2,
      reason: 'each job must be executed once, not once per overlapping trigger',
    );
    expect(queue.successes, ['job-n1', 'job-n2']);
  });

  test('I — a failing log trim does not fail the cycle', () async {
    // Trimming is housekeeping and runs in the `finally`. A throw there would
    // escape the block and replace whatever the `catch` had just handled — the
    // cycle would be reported as failed for tidying up badly.
    // `_cycleCount` is static and trims every 50th cycle, so running 50 empty
    // cycles crosses the boundary whatever the count happened to start at.
    final engine = buildEngine(
      _SelectiveExecutor(failFor: const {}),
      opsLog: _ThrowingTrimLog(),
    );

    for (var i = 0; i < 50; i++) {
      await expectLater(engine.runPendingJobs(), completes);
    }
  });

  test('G — a manual conflict retires the job instead of re-pushing forever',
      () async {
    // `ManualResolutionRequired` advanced nothing: not retry_count, not
    // next_retry_at. The row stayed immediately due, so every cycle re-sent it,
    // got the same 409 and landed here again — an unbounded loop for a conflict
    // that by definition waits for a person. `retry_count < max_retries` could
    // not bound it either, because the count never moved.
    entities.put(
      SyncEntityRecord(
        localId: 'n1',
        entityName: 'notes',
        serverId: 'n1',
        dataJson: jsonEncode({'id': 'n1', 'title': 'mine', 'version': 1}),
        updatedAt: 1,
        version: 1,
        syncStatus: SyncStatus.pending,
        isDeleted: false,
      ),
    );
    queue.seed([job('n1', maxRetries: 5)]);

    // The strategy that exists to refuse an automatic answer.
    await di.reset();
    di
      ..enableRegisteringMultipleInstancesOfOneType()
      ..registerSingleton<SyncFeatureContractBase>(
        const _NotesContract(conflictStrategy: SyncConflictStrategy.manual),
      );

    final engine = buildEngine(
      NotesSyncExecutor(
        _ThrowingDataSource(
          _dioError(409, {
            'status': false,
            'message': 'conflict',
            'data': {'conflict_fields': <String>['title']},
          }),
        ),
      ),
    );

    await engine.runPendingJobs();

    expect(queue.states.last.status, SyncStatus.conflicted);
    expect(queue.successes, isEmpty, reason: 'a manual conflict is not resolved');
    expect(
      queue.retries.single.retryCount,
      5,
      reason: 'the job must stop being due — otherwise it re-pushes forever',
    );
  });

  test('F — one failing job does not stop the two behind it', () async {
    queue.seed([job('n1'), job('n2'), job('n3')]);
    final engine = buildEngine(
      _SelectiveExecutor(failFor: {'n1'}),
    );

    await engine.runPendingJobs();

    expect(queue.successes, ['job-n2', 'job-n3']);
    expect(queue.retries.map((r) => r.jobId), ['job-n1']);
  });
}

DioException _dioError(int status, Map<String, dynamic> body) {
  final options = RequestOptions(path: '/notes/n1');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

// ── Doubles ──────────────────────────────────────────────────────────────────

class _Retry {
  _Retry(this.jobId, this.retryCount, this.nextRetryAt);
  final String jobId;
  final int retryCount;
  final int nextRetryAt;
}

class _State {
  _State(this.localId, this.status);
  final String localId;
  final SyncStatus status;
}

/// In-memory queue that honours the same due-job predicate the SQL does.
class _RecordingQueue implements SyncQueueRepository {
  final List<SyncQueueJob> _jobs = [];
  final List<_Retry> retries = [];
  final List<String> successes = [];
  final List<String> deleted = [];
  final List<_State> states = [];
  int pollCount = 0;

  void seed(List<SyncQueueJob> jobs) => _jobs
    ..clear()
    ..addAll(jobs);

  @override
  Future<List<SyncQueueJob>> getDueJobs({
    required int nowMs,
    required int limit,
  }) async {
    pollCount++;
    return _jobs
        .where((j) => j.nextRetryAt <= nowMs && j.retryCount < j.maxRetries)
        .take(limit)
        .toList();
  }

  @override
  Future<void> markJobRetry({
    required String jobId,
    required int retryCount,
    required int nextRetryAt,
    required String? lastError,
  }) async {
    retries.add(_Retry(jobId, retryCount, nextRetryAt));
    _jobs.removeWhere((j) => j.jobId == jobId); // no longer due this cycle
  }

  @override
  Future<void> markJobSuccess({required String jobId}) async {
    successes.add(jobId);
    deleted.add(jobId);
    _jobs.removeWhere((j) => j.jobId == jobId);
  }

  @override
  Future<void> markEntitySyncState({
    required String entityName,
    required String localId,
    required SyncStatus status,
    String? serverId,
    String? lastError,
  }) async =>
      states.add(_State(localId, status));

  @override
  Future<List<SyncQueueJob>> getAllJobs({int limit = 500}) async => _jobs;

  @override
  Future<int> countPendingJobs() async => _jobs.length;

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
  }) async {}

  @override
  Future<void> updateJobPayloadAndVersion({
    required String jobId,
    required String payloadJson,
    required int contractVersion,
  }) async {}
}

class _MemoryEntityStore implements SyncEntityStore {
  final Map<String, SyncEntityRecord> _rows = {};
  final List<SyncEntityRecord> upserted = [];

  void put(SyncEntityRecord r) => _rows[r.localId] = r;

  @override
  Future<SyncEntityRecord?> getRecordByLocalId({
    required String entityName,
    required String localId,
  }) async =>
      _rows[localId];

  @override
  Future<void> upsertRecord(SyncEntityRecord record) async {
    upserted.add(record);
    _rows[record.localId] = record;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('SyncEntityStore.${invocation.memberName} unexpected');
}

class _ThrowingExecutor implements SyncExecutor {
  _ThrowingExecutor(this._error);
  final Object _error;

  @override
  String get entityName => 'notes';

  @override
  Set<int> get supportedContractVersions => const {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async =>
      throw _error;
}

class _SelectiveExecutor implements SyncExecutor {
  _SelectiveExecutor({required this.failFor});
  final Set<String> failFor;

  @override
  String get entityName => 'notes';

  @override
  Set<int> get supportedContractVersions => const {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async {
    if (failFor.contains(job.entityId)) throw Exception('boom ${job.entityId}');
    return Right(SyncExecutionResult(localId: job.entityId, serverId: job.entityId));
  }
}

/// A datasource whose every write throws the supplied error — the shape a
/// non-2xx response actually takes once Dio has raised.
class _ThrowingDataSource extends NotesRemoteDataSource {
  _ThrowingDataSource(this._error) : super(_UnusedApi());

  final DioException _error;

  @override
  Future<ApiResponse<NoteModel>> create(
    NoteRequestDto body, {
    String? idempotencyKey,
  }) async =>
      throw _error;

  @override
  Future<ApiResponse<NoteModel>> update(
    String id,
    NoteRequestDto body, {
    String? idempotencyKey,
  }) async =>
      throw _error;

  @override
  Future<ApiResponse<Object?>> delete(
    String id, {
    int? version,
    String? idempotencyKey,
  }) async =>
      throw _error;
}

class _UnusedApi implements NotesApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('NotesApiService must not be reached');
}

class _FixedSettings implements SyncSettingsStore {
  @override
  Future<SyncSettings> getSettings() async => const SyncSettings(
        mode: SyncMode.active,
        syncEnabled: true,
        wifiOnly: false,
        periodicIntervalSeconds: 300,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) async {}
}

class _MemoryStorage implements StorageService {
  final Map<String, String> _values = {};

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('StorageService.${invocation.memberName} unexpected');
}

class _SilentOpsLog extends SyncOperationsLog {
  _SilentOpsLog() : super(SyncDatabase());

  @override
  Future<void> log({
    required String entityName,
    required String entityId,
    required SyncLogOperation operation,
    String? jobId,
    String? serverId,
    String? errorCode,
    String? errorDetail,
    String? payloadSnapshot,
  }) async {}

  @override
  Future<void> trim() async {}
}

class _NotesContract extends SyncFeatureContractBase {
  const _NotesContract({
    this.conflictStrategy = SyncConflictStrategy.serverWins,
  });

  @override
  final SyncConflictStrategy conflictStrategy;

  @override
  String get entityName => 'notes';

  @override
  Type get repositoryContractType => Object;

  @override
  Object resolveRepository(GetIt di) => Object();
}

class _SilentLog implements LogDelegate {
  const _SilentLog();
  @override
  void warning(String message, {String? tag}) {}
  @override
  void info(String message, {String? tag}) {}
  @override
  void debug(String message, {String? tag}) {}
  @override
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {}
}

class _CountingExecutor implements SyncExecutor {
  int calls = 0;

  @override
  String get entityName => 'notes';

  @override
  Set<int> get supportedContractVersions => const {1};

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async {
    calls++;
    // A suspension point, so an overlapping cycle has somewhere to interleave.
    await Future<void>.delayed(Duration.zero);
    return Right(SyncExecutionResult(localId: job.entityId, serverId: job.entityId));
  }
}

/// Trims badly. Housekeeping must not be able to fail a cycle that worked.
class _ThrowingTrimLog extends SyncOperationsLog {
  _ThrowingTrimLog() : super(SyncDatabase());

  @override
  Future<void> log({
    required String entityName,
    required String entityId,
    required SyncLogOperation operation,
    String? jobId,
    String? serverId,
    String? errorCode,
    String? errorDetail,
    String? payloadSnapshot,
  }) async {}

  @override
  Future<void> trim() async => throw StateError('trim exploded');
}
