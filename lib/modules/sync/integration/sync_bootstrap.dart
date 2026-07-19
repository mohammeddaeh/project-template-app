import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/data/sql_sync_entity_store.dart';
import 'package:app_template/modules/sync/data/sql_sync_queue_repository.dart';
import 'package:app_template/modules/sync/data/sql_sync_write_gateway.dart';
import 'package:app_template/modules/sync/data/sync_database.dart';
import 'package:app_template/modules/sync/data/sync_operations_log.dart';
import 'package:app_template/modules/sync/domain/sync_entity_store.dart';
import 'package:app_template/modules/sync/domain/sync_queue_repository.dart';
import 'package:app_template/modules/sync/domain/sync_write_gateway.dart';
import 'package:app_template/modules/sync/engine/sync_backoff_policy.dart';
import 'package:app_template/modules/sync/engine/sync_conflict_resolver.dart';
import 'package:app_template/modules/sync/engine/sync_engine.dart';
import 'package:app_template/modules/sync/integration/sync_controller.dart';
import 'package:app_template/modules/sync/integration/sync_lock.dart';
import 'package:app_template/modules/sync/integration/sync_repository_decorator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_migrator.dart';
import 'package:app_template/modules/sync/validation/sync_contract_validator.dart';
import 'package:uuid/uuid.dart';

Future<void> registerSyncCore(GetIt getIt) async {
  getIt.enableRegisteringMultipleInstancesOfOneType();

  if (!getIt.isRegistered<SyncDatabase>()) {
    getIt.registerLazySingleton<SyncDatabase>(SyncDatabase.new);
  }
  if (!getIt.isRegistered<SyncOperationsLog>()) {
    getIt.registerLazySingleton<SyncOperationsLog>(
      () => SyncOperationsLog(getIt<SyncDatabase>()),
    );
  }
  if (!getIt.isRegistered<SyncEntityStore>()) {
    getIt.registerLazySingleton<SyncEntityStore>(
      () => SqlSyncEntityStore(getIt<SyncDatabase>()),
    );
  }
  if (!getIt.isRegistered<SyncQueueRepository>()) {
    getIt.registerLazySingleton<SyncQueueRepository>(
      () => SqlSyncQueueRepository(getIt<SyncDatabase>()),
    );
  }
  if (!getIt.isRegistered<SyncSettingsStore>()) {
    getIt.registerLazySingleton<SyncSettingsStore>(
      () => SharedPrefsSyncSettingsStore(getIt()),
    );
  }
  if (!getIt.isRegistered<SyncBackoffPolicy>()) {
    getIt.registerLazySingleton<SyncBackoffPolicy>(SyncBackoffPolicy.new);
  }
  if (!getIt.isRegistered<SyncConflictResolver>()) {
    getIt.registerLazySingleton<SyncConflictResolver>(SyncConflictResolver.new);
  }
  if (!getIt.isRegistered<SyncLock>()) {
    getIt.registerLazySingleton<SyncLock>(
      () => SyncLock(getIt<StorageService>()),
    );
  }
  if (!getIt.isRegistered<SyncContractMigrator>()) {
    getIt.registerLazySingleton<SyncContractMigrator>(
      () => SyncContractMigrator(getIt),
    );
  }
  if (!getIt.isRegistered<SyncContractValidator>()) {
    getIt.registerLazySingleton<SyncContractValidator>(
      () => SyncContractValidator(
        getIt,
        getIt<SyncQueueRepository>(),
        getIt<SyncContractMigrator>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncWriteGateway>()) {
    getIt.registerLazySingleton<SyncWriteGateway>(
      () => SqlSyncWriteGateway(
        getIt<SyncDatabase>(),
        getIt<SyncSettingsStore>(),
        getIt<Uuid>(),
        getIt<SyncContractValidator>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncEngine>()) {
    getIt.registerLazySingleton<SyncEngine>(
      () => SyncEngine(
        getIt<SyncSettingsStore>(),
        getIt<SyncQueueRepository>(),
        getIt<SyncEntityStore>(),
        getIt<SyncBackoffPolicy>(),
        getIt,
        getIt<SyncContractMigrator>(),
        getIt<SyncContractValidator>(),
        getIt<SyncConflictResolver>(),
        getIt<SyncLock>(),
        getIt<SyncOperationsLog>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncController>()) {
    getIt.registerLazySingleton<SyncController>(
      () => SyncController(
        getIt<SyncSettingsStore>(),
        getIt<Connectivity>(),
        getIt<SyncEngine>(),
      ),
    );
  }
}

Future<void> applySyncRepositoryDecorators(GetIt getIt) async {
  if (!getIt.isRegistered<SyncRepositoryDecorator>()) return;
  final decorators = getIt.getAll<SyncRepositoryDecorator>();
  for (final decorator in decorators) {
    await decorator.decorate(getIt);
  }
}
