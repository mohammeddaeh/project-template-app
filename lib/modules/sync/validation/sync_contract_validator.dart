import 'dart:convert';

import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/logging/log_service.dart';

import '../automation/sync_feature_contract.dart';
import '../domain/sync_write_gateway.dart';
import '../domain/syncable_repository.dart';
import '../domain/sync_queue_repository.dart';
import '../engine/sync_job_executor.dart';
import '../integration/sync_repository_decorator.dart';
import 'sync_contract_migrator.dart';
import 'sync_contract_validation_exception.dart';

class SyncContractValidator {
  SyncContractValidator(
    this._di,
    this._queueRepository,
    this._migrator,
  );

  // GetIt is injected rather than pre-resolved lists because this validator
  // runs during SyncSDK.initialize() after decorators are applied and must
  // reflect the final DI state. Resolving lists at construction time would
  // capture a stale snapshot of multi-bound registrations.
  final GetIt _di;
  final SyncQueueRepository _queueRepository;
  final SyncContractMigrator _migrator;

  /// Returns `true` when the module is configured well enough to start.
  ///
  /// ## «غير مُعدّ» ليست حالة خطأ — وهذا التمييز هو كل الفرق
  ///
  /// كانت هذه الدالة ترمي على القائمة الفارغة: مشروعٌ يقلب
  /// `AppFeatures.offlineSync` إلى `true` قبل أن يكتب أول عقد كان **يفقد
  /// الإقلاع كلياً** — الرمية تصعد عبر `SyncSDK.initialize` ثم
  /// `ModulesBootstrap.initializeAll` إلى `_bootstrap` **قبل `runApp`**، فلا
  /// شاشة ولا رسالة ولا أثر يدلّ على أن السبب علمٌ قُلب.
  ///
  /// والعلَم في هذا القالب عقدٌ معناه «أشعل الموديول أو دعه مطفأً» — لا
  /// «أسقط التطبيق». فصفر عقود تعني الآن: الموديول غير مُعدّ بعد، يُسجَّل
  /// ويُترك مطفأً، والتطبيق يعمل.
  ///
  /// أمّا **التعارض الحقيقي** فيبقى رمياً: executor مكرَّر · عقد بلا executor
  /// يشترطه · نسخة عقد لا يدعمها executor. هذه ليست «لم يُعَدّ بعد» بل
  /// «أُعِدّ خطأً»، وتمريرها بصمت يعني طابوراً يُنفَّذ بالمُنفِّذ الخطأ.
  bool validatePreInitialization() {
    _validateCoreDependencies(_di);

    final readiness = _describeReadiness(_di);
    if (readiness != null) {
      LogService.warning(
        'Sync module NOT started — $readiness. '
        'The app runs normally with sync disabled. '
        'See lib/modules/sync/SETUP.md to configure it.',
        tag: 'SYNC',
      );
      return false;
    }

    _validateExecutorContracts(_di);
    return true;
  }

  /// Returns a human-readable reason when the module is simply not configured,
  /// or `null` when it has everything it needs to start.
  String? _describeReadiness(GetIt di) {
    if (_allContracts(di).isEmpty) {
      return 'no SyncFeatureContractBase is registered';
    }
    if (!di.isRegistered<SyncExecutor>()) {
      return 'no SyncExecutor is registered';
    }
    if (!di.isRegistered<SyncRepositoryDecorator>()) {
      return 'no SyncRepositoryDecorator is registered';
    }
    return null;
  }

  void validatePostDecoration() {
    _validateRepositoryCompliance(_di);
  }

  void validateQueuePayload({
    required String entityName,
    required String payloadJson,
    required int contractVersion,
  }) {
    final migration = _migrator.migratePayloadToLatest(
      entityName: entityName,
      payloadJson: payloadJson,
      fromVersion: contractVersion,
    );
    final contract = _findContractByEntityName(_di, entityName);
    if (contract == null) {
      throw SyncContractValidationException(
        'missing sync feature contract for entity "$entityName". '
        'Queue payload cannot be validated.',
      );
    }

    final decoded = jsonDecode(migration.payloadJson);
    if (decoded is! Map<String, dynamic>) {
      throw SyncContractValidationException(
        'invalid queue payload for entity "$entityName": payload must be a JSON object.',
      );
    }
    if (!contract.isValidQueuePayload(decoded)) {
      throw SyncContractValidationException(
        'invalid queue payload structure for entity "$entityName".',
      );
    }
  }

  Future<void> migrateAndValidateQueuedJobs() async {
    final jobs = await _queueRepository.getAllJobs();
    for (final job in jobs) {
      final migration = _migrator.migratePayloadToLatest(
        entityName: job.entityName,
        payloadJson: job.payloadJson,
        fromVersion: job.contractVersion,
      );

      final contract = _findContractByEntityName(_di, job.entityName);
      if (contract == null) {
        throw SyncContractValidationException(
          'missing sync feature contract for entity "${job.entityName}".',
        );
      }

      final decoded = jsonDecode(migration.payloadJson);
      if (decoded is! Map<String, dynamic> || !contract.isValidQueuePayload(decoded)) {
        throw SyncContractValidationException(
          'invalid payload in queued job "${job.jobId}" for entity "${job.entityName}".',
        );
      }

      if (migration.migrated) {
        await _queueRepository.updateJobPayloadAndVersion(
          jobId: job.jobId,
          payloadJson: migration.payloadJson,
          contractVersion: migration.contractVersion,
        );
      }
    }
  }

  void _validateCoreDependencies(GetIt di) {
    if (!di.isRegistered<SyncWriteGateway>()) {
      throw SyncContractValidationException(
        'sync write gateway is not registered in DI graph.',
      );
    }
  }

  /// Runs only after [_describeReadiness] confirmed contracts and executors
  /// exist — so everything it throws is a genuine misconfiguration, never a
  /// "not set up yet".
  void _validateExecutorContracts(GetIt di) {
    final contracts = _allContracts(di);

    // Build Map<entityName, SyncExecutor> and count duplicates in one pass — O(m).
    // This avoids a repeated firstWhere() inside the version-check loop below (was O(n×m)).
    final Map<String, SyncExecutor> executorMap = <String, SyncExecutor>{};
    final Map<String, int> counts = <String, int>{};
    for (final executor in di.getAll<SyncExecutor>()) {
      counts[executor.entityName] = (counts[executor.entityName] ?? 0) + 1;
      executorMap[executor.entityName] = executor;
    }

    final duplicates = counts.entries.where((entry) => entry.value > 1).toList();
    if (duplicates.isNotEmpty) {
      final names = duplicates.map((e) => '${e.key}(${e.value})').join(', ');
      throw SyncContractValidationException(
        'duplicate sync executors detected for entity names: $names',
      );
    }

    final requiredEntities = contracts
        .where((c) => c.requiresExecutor)
        .map((c) => c.entityName)
        .toSet();
    final missing = requiredEntities.where((e) => !executorMap.containsKey(e)).toList();
    if (missing.isNotEmpty) {
      throw SyncContractValidationException(
        'missing executor for entities: ${missing.join(', ')}',
      );
    }

    for (final contract in contracts.where((c) => c.requiresExecutor)) {
      // O(1) lookup — safe because missing-check above guarantees presence.
      final executor = executorMap[contract.entityName]!;
      if (!executor.supportedContractVersions.contains(contract.contractVersion)) {
        throw SyncContractValidationException(
          'executor "${executor.runtimeType}" for entity "${contract.entityName}" '
          'does not support current contract version ${contract.contractVersion}.',
        );
      }
    }
  }

  void _validateRepositoryCompliance(GetIt di) {
    final contracts = _allContracts(di);
    for (final contract in contracts) {
      final Type repositoryType = contract.repositoryContractType;
      Object instance;
      try {
        instance = contract.resolveRepository(di);
      } catch (_) {
        throw SyncContractValidationException(
          'repository binding missing for contract type "$repositoryType".',
        );
      }
      if (instance is! SyncableRepository) {
        throw SyncContractValidationException(
          'repository "$repositoryType" is not SyncableRepository compliant.',
        );
      }
    }
  }

  SyncFeatureContractBase? _findContractByEntityName(GetIt di, String entityName) {
    for (final contract in _allContracts(di)) {
      if (contract.entityName == entityName) {
        return contract;
      }
    }
    return null;
  }

  List<SyncFeatureContractBase> _allContracts(GetIt di) {
    if (!di.isRegistered<SyncFeatureContractBase>()) {
      return const <SyncFeatureContractBase>[];
    }
    return di.getAll<SyncFeatureContractBase>().toList();
  }
}
