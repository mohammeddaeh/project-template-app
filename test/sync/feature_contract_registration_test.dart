import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/Features/notes/data/sync/notes_feature_contract.dart';
import 'package:app_template/core/foundation/errors/failure.dart';
import 'package:app_template/core/platform/logging/log_service.dart';
import 'package:app_template/modules/sync/sync_plugin.dart';
import 'package:app_template/modules/sync/validation/sync_contract_migrator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validator.dart';

/// Proves the sync module can actually **find** a feature contract.
///
/// ## The defect this exists for
///
/// `GetIt` keys its registry by the literal type: `getAll<T>()` is a lookup on
/// `typeRegistrations[T]` and nothing more. `NotesFeatureContract` was annotated
/// `@LazySingleton()`, so `build_runner` registered it under
/// `NotesFeatureContract` — while `SyncContractValidator` and `SyncEngine` both
/// ask for `SyncFeatureContractBase`. The lookup returned `[]`.
///
/// The observable result was the worst shape a defect can take: setting
/// `AppFeatures.offlineSync = true` produced an app that ran **fully online**.
/// `SyncSDK.initialize` logged "no SyncFeatureContractBase is registered" and
/// returned, no repository was decorated, nothing threw, `dart analyze` was
/// clean, and every existing test passed.
///
/// ## Why every existing test passed
///
/// `sync_bootstrap_safety_test.dart` registers its fakes as
/// `di.registerSingleton<SyncFeatureContractBase>(…)` — by hand, with the type
/// the validator asks for. That is the right shape to test *validator logic*
/// with, and it is exactly the wrong shape to catch this with: it asserts on a
/// registration the generator does not produce.
///
/// So this file does the opposite on purpose. It registers **the real
/// `NotesFeatureContract`, in the exact form `injection.config.dart` emits it**,
/// and never hand-registers the base type. If the `as:` is dropped from the
/// annotation, the first test here fails.
void main() {
  late GetIt di;

  setUp(() {
    di = GetIt.asNewInstance()..enableRegisteringMultipleInstancesOfOneType();
    LogService.setDelegate(const _SilentLogDelegate());
  });

  tearDown(() async {
    LogService.setDelegate(const _SilentLogDelegate());
    await di.reset();
  });

  /// Mirrors `injection.config.dart` line for line:
  ///
  /// ```dart
  /// gh.lazySingleton<SyncFeatureContractBase>(
  ///   () => const NotesFeatureContract(),
  /// );
  /// ```
  ///
  /// Written out rather than calling `configureInjection`, which would drag in
  /// Hive, secure storage, Dio and a platform channel apiece. The shape is what
  /// matters, and the shape is asserted against the generated file below.
  void registerAsGenerated() {
    di.registerLazySingleton<SyncFeatureContractBase>(
      () => const NotesFeatureContract(),
    );
  }

  SyncContractValidator buildValidator() => SyncContractValidator(
        di,
        _FakeQueueRepository(),
        SyncContractMigrator(di),
      );

  group('discovery', () {
    test('the generated registration is visible to getAll<SyncFeatureContractBase>', () {
      registerAsGenerated();

      final contracts = di.getAll<SyncFeatureContractBase>().toList();

      expect(
        contracts,
        hasLength(1),
        reason: 'getAll<SyncFeatureContractBase>() found nothing. The contract '
            'is registered under its own concrete type again — restore '
            '@LazySingleton(as: SyncFeatureContractBase) on NotesFeatureContract '
            'and re-run build_runner.',
      );
      expect(contracts.single, isA<NotesFeatureContract>());
      expect(contracts.single.entityName, 'notes');
    });

    test('the isRegistered guard every caller passes through also sees it', () {
      registerAsGenerated();

      // Not redundant with the test above, and this is the subtle half of the
      // defect. `SyncContractValidator._allContracts`, `SyncEngine._resolveContract`
      // and `SyncContractMigrator._findContractByEntityName` all open with the
      // same line:
      //
      //     if (!di.isRegistered<SyncFeatureContractBase>()) return const [];
      //
      // so `getAll` finding the contract is worth nothing if this answers false.
      expect(di.isRegistered<SyncFeatureContractBase>(), isTrue);
    });

    test('registering under the concrete type is invisible — defect, first half', () {
      // The line build_runner emitted before the fix. From the container's side,
      // this is what "the module silently does nothing" looks like.
      di.registerLazySingleton<NotesFeatureContract>(
        () => const NotesFeatureContract(),
      );

      expect(di.isRegistered<SyncFeatureContractBase>(), isFalse);
      // `getAll` does not even return an empty list for an unregistered type —
      // it throws. Which is why every caller guards with `isRegistered` first,
      // and why that guard is the thing that has to answer correctly.
      expect(() => di.getAll<SyncFeatureContractBase>(), throwsStateError);
    });

    test('a named-only registration is invisible to the guard — defect, second half', () {
      // The shape `@LazySingleton(as: SyncFeatureContractBase)` + `@Named(...)`
      // produces. It looks fixed: `getAll` finds the contract, because it merges
      // named and unnamed registrations. But `isRegistered<T>()` with no
      // instanceName reads only the *unnamed* list
      // (`getRegistration(null)` → `registrations.firstOrNull`), so the guard in
      // front of every `getAll` short-circuits and the module stays dead.
      //
      // This is why the annotation carries no `@Named`, and this test is the
      // reason anyone would know not to add one back.
      di.registerLazySingleton<SyncFeatureContractBase>(
        () => const NotesFeatureContract(),
        instanceName: 'sync_feature_contracts',
      );

      expect(di.getAll<SyncFeatureContractBase>(), hasLength(1));
      expect(di.isRegistered<SyncFeatureContractBase>(), isFalse);
    });
  });

  group('validatePreInitialization', () {
    test('succeeds with the real contract registered as the generator emits it', () {
      registerAsGenerated();
      di
        ..registerLazySingleton<SyncWriteGateway>(_FakeWriteGateway.new)
        ..registerSingleton<SyncExecutor>(const _NotesExecutor())
        ..registerSingleton<SyncRepositoryDecorator>(_NoopDecorator());

      expect(
        buildValidator().validatePreInitialization(),
        isTrue,
        reason: 'The module refused to start with a correctly configured '
            'contract, executor and decorator present. This is the check that '
            'gates SyncSDK.initialize — false here means AppFeatures.offlineSync '
            '= true leaves the app running online.',
      );
    });

    test('without the contract it refuses — the check is not vacuous', () {
      // Same graph minus the contract. A test that only ever sees `true` proves
      // nothing about what the `true` depends on.
      di
        ..registerLazySingleton<SyncWriteGateway>(_FakeWriteGateway.new)
        ..registerSingleton<SyncExecutor>(const _NotesExecutor())
        ..registerSingleton<SyncRepositoryDecorator>(_NoopDecorator());

      expect(buildValidator().validatePreInitialization(), isFalse);
    });
  });

  test('injection.config.dart registers the contract under the base type', () {
    // The behavioural tests above describe the generated shape; this one checks
    // the generator still produces it. Without this pair, dropping the `as:`
    // would leave every test above passing against a shape nothing emits —
    // which is precisely how the defect survived in the first place.
    final generated = File('lib/core/di/injection.config.dart');
    expect(generated.existsSync(), isTrue);

    final registration = RegExp(
      r'lazySingleton<_i\d+\.SyncFeatureContractBase>\(\s*\(\) =>'
      r'\s*const _i\d+\.NotesFeatureContract\(\),\s*\);',
    );

    expect(
      registration.hasMatch(generated.readAsStringSync()),
      isTrue,
      reason: 'injection.config.dart no longer registers NotesFeatureContract '
          'as an unnamed SyncFeatureContractBase. Either the annotation lost '
          'its `as:`, or it gained a `@Named` (which hides it from '
          'isRegistered), or build_runner has not been re-run since it changed.',
    );
  });
}

// ── Fakes ────────────────────────────────────────────────────────────────────

class _NotesExecutor implements SyncExecutor {
  const _NotesExecutor();

  @override
  String get entityName => 'notes';

  @override
  Set<int> get supportedContractVersions => const {1};

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
