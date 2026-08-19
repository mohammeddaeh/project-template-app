import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/sync/automation/sync_feature_contract.dart';
import 'package:app_template/modules/sync/domain/sync_queue_job.dart';
import 'package:app_template/modules/sync/domain/sync_queue_repository.dart';
import 'package:app_template/modules/sync/domain/sync_status.dart';
import 'package:app_template/modules/sync/domain/sync_write_gateway.dart';
import 'package:app_template/modules/sync/domain/syncable_repository.dart';
import 'package:app_template/modules/sync/engine/sync_job_executor.dart';
import 'package:app_template/modules/sync/integration/sync_repository_decorator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_migrator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validation_exception.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validator.dart';

/// Guards the P0 rule from `lib/modules/sync/PLAN.md`:
///
/// > **علم الموديول يُشعله أو يُعطّله — ولا يُسقط التطبيق أبداً.**
///
/// `AppFeatures.offlineSync = true` on a project that has not written its
/// first contract used to throw out of `SyncSDK.initialize`, up through
/// `ModulesBootstrap.initializeAll`, into `main._bootstrap()` — which runs
/// **before `runApp`**. The observable result was an app that never rendered a
/// frame, with nothing tying the black screen back to the flag.
///
/// The distinction this file locks down: **"not configured yet" is not an
/// error, "configured wrong" is.**
void main() {
  late GetIt di;
  late _CapturingLogDelegate logs;

  setUp(() {
    di = GetIt.asNewInstance()..enableRegisteringMultipleInstancesOfOneType();
    logs = _CapturingLogDelegate();
    LogService.setDelegate(logs);
    // Core dependency the validator always requires — registered by
    // `registerSyncCore` before validation runs in the real bootstrap.
    di.registerLazySingleton<SyncWriteGateway>(_FakeWriteGateway.new);
  });

  tearDown(() async {
    LogService.setDelegate(const _SilentLogDelegate());
    await di.reset();
  });

  SyncContractValidator buildValidator() => SyncContractValidator(
        di,
        _FakeQueueRepository(),
        SyncContractMigrator(di),
      );

  group('«لم يُعَدّ بعد» — يُعطَّل ولا يرمي', () {
    test('صفر عقود: يعيد false ولا يرمي', () {
      final validator = buildValidator();

      expect(validator.validatePreInitialization(), isFalse);
      expect(
        logs.warnings.join('\n'),
        contains('no SyncFeatureContractBase is registered'),
      );
    });

    test('عقد بلا executor مسجَّل إطلاقاً: يعيد false ولا يرمي', () {
      di.registerSingleton<SyncFeatureContractBase>(const _NotesContract());
      di.registerLazySingleton<_NotesRepository>(_NotesRepository.new);

      final validator = buildValidator();

      expect(validator.validatePreInitialization(), isFalse);
      expect(
        logs.warnings.join('\n'),
        contains('no SyncExecutor is registered'),
      );
    });

    test('عقد وexecutor بلا decorator: يعيد false ولا يرمي', () {
      di.registerSingleton<SyncFeatureContractBase>(const _NotesContract());
      di.registerLazySingleton<_NotesRepository>(_NotesRepository.new);
      di.registerSingleton<SyncExecutor>(const _Executor('notes'));

      final validator = buildValidator();

      expect(validator.validatePreInitialization(), isFalse);
      expect(
        logs.warnings.join('\n'),
        contains('no SyncRepositoryDecorator is registered'),
      );
    });

    test('كل تعطيل يقول للمستخدم أن التطبيق يعمل، وأين يقرأ', () {
      buildValidator().validatePreInitialization();

      final warning = logs.warnings.join('\n');
      expect(warning, contains('Sync module NOT started'));
      expect(warning, contains('app runs normally'));
      expect(warning, contains('SETUP.md'));
    });
  });

  group('«أُعِدّ خطأً» — يبقى رمياً', () {
    setUp(() {
      di.registerLazySingleton<_NotesRepository>(_NotesRepository.new);
      di.registerSingleton<SyncRepositoryDecorator>(_NoopDecorator());
    });

    test('executor مكرَّر لنفس الكيان يرمي', () {
      di.registerSingleton<SyncFeatureContractBase>(const _NotesContract());
      di
        ..registerSingleton<SyncExecutor>(const _Executor('notes'))
        ..registerSingleton<SyncExecutor>(const _Executor('notes'));

      expect(
        buildValidator().validatePreInitialization,
        throwsA(
          isA<SyncContractValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('duplicate'),
          ),
        ),
      );
    });

    test('عقد يشترط executor ولا executor له يرمي', () {
      di
        ..registerSingleton<SyncFeatureContractBase>(const _NotesContract())
        ..registerSingleton<SyncFeatureContractBase>(const _TasksContract());
      di.registerSingleton<SyncExecutor>(const _Executor('notes'));

      expect(
        buildValidator().validatePreInitialization,
        throwsA(
          isA<SyncContractValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('tasks'),
          ),
        ),
      );
    });

    test('executor لا يدعم نسخة العقد يرمي', () {
      di.registerSingleton<SyncFeatureContractBase>(const _NotesContract(version: 3));
      di.registerSingleton<SyncExecutor>(
        const _Executor('notes', supported: {1, 2}),
      );

      expect(
        buildValidator().validatePreInitialization,
        throwsA(isA<SyncContractValidationException>()),
      );
    });

    test('الإعداد السليم يمرّ ويعيد true', () {
      di.registerSingleton<SyncFeatureContractBase>(const _NotesContract());
      di.registerSingleton<SyncExecutor>(const _Executor('notes'));

      expect(buildValidator().validatePreInitialization(), isTrue);
      expect(logs.warnings, isEmpty);
    });
  });
}

// ── Fakes ────────────────────────────────────────────────────────────────────

class _NotesRepository extends SyncableRepository {
  _NotesRepository() : super(_FakeWriteGateway());
}

class _NotesContract extends SyncFeatureContractBase {
  const _NotesContract({int version = 1}) : _version = version;

  final int _version;

  @override
  String get entityName => 'notes';
  @override
  int get contractVersion => _version;
  @override
  Type get repositoryContractType => _NotesRepository;
  @override
  Object resolveRepository(GetIt di) => di<_NotesRepository>();
}

class _TasksContract extends SyncFeatureContractBase {
  const _TasksContract();

  @override
  String get entityName => 'tasks';
  @override
  Type get repositoryContractType => _NotesRepository;
  @override
  Object resolveRepository(GetIt di) => di<_NotesRepository>();
}

class _Executor implements SyncExecutor {
  const _Executor(this.entityName, {this.supported = const {1}});

  @override
  final String entityName;
  final Set<int> supported;

  @override
  Set<int> get supportedContractVersions => supported;

  @override
  Future<Either<Failure, SyncExecutionResult>> execute(
    SyncQueueJob job,
    int contractVersion,
  ) async =>
      Right(SyncExecutionResult(localId: job.entityId));
}

class _NoopDecorator implements SyncRepositoryDecorator {
  @override
  Future<void> decorate(GetIt getIt) async {}
}

class _FakeWriteGateway implements SyncWriteGateway {
  @override
  Future<void> write(SyncWriteCommand command) async {}
}

class _FakeQueueRepository implements SyncQueueRepository {
  @override
  Future<List<SyncQueueJob>> getAllJobs({int limit = 500}) async => const [];

  @override
  Future<List<SyncQueueJob>> getDueJobs({
    required int nowMs,
    required int limit,
  }) async =>
      const [];

  @override
  Future<int> countPendingJobs() async => 0;

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
  Future<void> markEntitySyncState({
    required String entityName,
    required String localId,
    required SyncStatus status,
    String? serverId,
    String? lastError,
  }) async {}

  @override
  Future<void> markJobRetry({
    required String jobId,
    required int retryCount,
    required int nextRetryAt,
    required String? lastError,
  }) async {}

  @override
  Future<void> markJobSuccess({required String jobId}) async {}

  @override
  Future<void> updateJobPayloadAndVersion({
    required String jobId,
    required String payloadJson,
    required int contractVersion,
  }) async {}
}

class _CapturingLogDelegate implements LogDelegate {
  final List<String> warnings = [];

  @override
  void warning(String message, {String? tag}) => warnings.add(message);

  @override
  void info(String message, {String? tag}) {}

  @override
  void debug(String message, {String? tag}) {}

  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

class _SilentLogDelegate implements LogDelegate {
  const _SilentLogDelegate();

  @override
  void warning(String message, {String? tag}) {}
  @override
  void info(String message, {String? tag}) {}
  @override
  void debug(String message, {String? tag}) {}
  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
