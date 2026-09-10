import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:app_template/core/foundation/contracts/auth_network_gateway.dart';
import 'package:app_template/core/infra/files/server_file_cache.dart';
import 'package:app_template/modules/sync/domain/media_prefetch_status.dart';
import 'package:app_template/modules/sync/engine/media_prefetch_manager.dart';
import 'package:app_template/modules/sync/engine/attachment_upload_progress.dart';
import 'package:app_template/core/foundation/di/get_it_all_extension.dart';
import 'package:app_template/core/foundation/contracts/local_data_wiper.dart';
import 'package:app_template/core/platform/lifecycle/app_lifecycle_service.dart';
import 'package:app_template/core/foundation/contracts/unsynced_work_probe.dart';
import 'package:dio/dio.dart';

import 'package:app_template/modules/sync/data/attachment_file_store.dart';
import 'package:app_template/modules/sync/integration/sync_local_data_wiper.dart';
import 'package:app_template/modules/sync/data/sql_attachment_store.dart';
import 'package:app_template/modules/sync/data/sync_cursor_store.dart';
import 'package:app_template/modules/sync/data/sync_cycle_stamp.dart';
import 'package:app_template/modules/sync/domain/attachment_store.dart';
import 'package:app_template/modules/sync/domain/sync_hydration.dart';
import 'package:app_template/modules/sync/domain/sync_queue_signal.dart';
import 'package:app_template/modules/sync/engine/attachment_cache_manager.dart';
import 'package:app_template/modules/sync/engine/attachment_capture.dart';
import 'package:app_template/modules/sync/engine/attachment_metadata_sync.dart';
import 'package:app_template/modules/sync/engine/attachment_upload_manager.dart';
import 'package:app_template/modules/sync/engine/attachment_download_manager.dart';
import 'package:app_template/modules/sync/integration/sync_gate.dart';
import 'package:app_template/core/platform/storage/storage_service.dart';
import 'package:app_template/modules/sync/integration/sync_unsynced_work_probe.dart';
import 'package:app_template/modules/sync/config/sync_settings_store.dart';
import 'package:app_template/modules/sync/data/sql_sync_entity_store.dart';
import 'package:app_template/modules/sync/data/sql_sync_queue_repository.dart';
import 'package:app_template/modules/sync/data/sql_sync_write_gateway.dart';
import 'package:app_template/modules/sync/data/sync_database.dart';
import 'package:app_template/modules/sync/data/sync_operations_log.dart';
import 'package:app_template/modules/sync/domain/sync_change_notifier.dart';
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
  // One notifier shared by all three writers of `synced_entities`. A listener
  // that heard only one of them would refresh sometimes, which reads as
  // flakiness rather than as a missing wire.
  if (!getIt.isRegistered<SyncChangeNotifier>()) {
    getIt.registerLazySingleton<SyncChangeNotifier>(SyncChangeNotifier.new);
  }
  if (!getIt.isRegistered<SyncEntityStore>()) {
    getIt.registerLazySingleton<SyncEntityStore>(
      () => SqlSyncEntityStore(
        getIt<SyncDatabase>(),
        getIt<SyncChangeNotifier>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncQueueRepository>()) {
    getIt.registerLazySingleton<SyncQueueRepository>(
      () => SqlSyncQueueRepository(
        getIt<SyncDatabase>(),
        getIt<SyncChangeNotifier>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncSettingsStore>()) {
    getIt.registerLazySingleton<SyncSettingsStore>(
      () => SharedPrefsSyncSettingsStore(getIt()),
    );
  }
  // Replaces the `NoUnsyncedWorkProbe` default registered in
  // `injection_module.dart`. Anything destructive — signing out, switching
  // accounts — asks this before it acts, and must get the real answer rather
  // than the one an app without a queue would give.
  if (getIt.isRegistered<UnsyncedWorkProbe>()) {
    await getIt.unregister<UnsyncedWorkProbe>();
  }
  getIt.registerLazySingleton<UnsyncedWorkProbe>(
    () => SyncUnsyncedWorkProbe(getIt<SyncQueueRepository>()),
  );

  // نفس الاستبدال بالضبط، وللسبب نفسه. الافتراضي `NoLocalDataWiper` لا يمحو
  // شيئاً — وهو الصواب لتطبيقٍ لا يحمل بياناتٍ محلية. ومع الموديول مُشعَلاً
  // يحمل الجهاز صفوفَ حسابٍ وطابورَه وصورَه، ومن يخرج ثم يُسلّم جهازه يتركها
  // كلَّها لمن بعده — **ويُدفع طابورُه بتوكن الداخل الجديد**.
  if (getIt.isRegistered<LocalDataWiper>()) {
    await getIt.unregister<LocalDataWiper>();
  }
  getIt.registerLazySingleton<LocalDataWiper>(
    () => SyncLocalDataWiper(
      getIt<SyncDatabase>(),
      getIt<AttachmentFileStore>(),
      getIt<StorageService>(),
    ),
  );

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
  // **«فارغ» جوابان لا جواب** — راجع `SyncHydration`.
  if (!getIt.isRegistered<SyncHydration>()) {
    getIt.registerLazySingleton<SyncHydration>(
      () => SyncHydration(getIt<SyncCursorStore>()),
    );
  }
  if (!getIt.isRegistered<SyncQueueSignal>()) {
    getIt.registerLazySingleton<SyncQueueSignal>(SyncQueueSignal.new);
  }
  if (!getIt.isRegistered<SyncWriteGateway>()) {
    getIt.registerLazySingleton<SyncWriteGateway>(
      () => SqlSyncWriteGateway(
        getIt<SyncDatabase>(),
        getIt<SyncSettingsStore>(),
        getIt<Uuid>(),
        getIt<SyncContractValidator>(),
        getIt<SyncChangeNotifier>(),
      )..queueSignal = getIt<SyncQueueSignal>(),
    );
  }
  // ── Attachments (P4.5) ─────────────────────────────────────────────────────
  if (!getIt.isRegistered<AttachmentFileStore>()) {
    getIt.registerLazySingleton<AttachmentFileStore>(AttachmentFileStore.new);
  }
  if (!getIt.isRegistered<AttachmentStore>()) {
    getIt.registerLazySingleton<AttachmentStore>(
      () => SqlAttachmentStore(getIt<SyncDatabase>()),
    );
  }
  if (!getIt.isRegistered<AttachmentDownloadManager>()) {
    getIt.registerLazySingleton<AttachmentDownloadManager>(
      // The **authenticated** Dio: attachment urls are private, and the plain
      // client in `FileService` exists for public downloads by design.
      () => AttachmentDownloadManager(
        getIt<Dio>(),
        getIt<AttachmentStore>(),
        getIt<AttachmentFileStore>(),
      ),
    );
  }
  if (!getIt.isRegistered<AttachmentCacheManager>()) {
    getIt.registerLazySingleton<AttachmentCacheManager>(
      () => AttachmentCacheManager(
        getIt<AttachmentStore>(),
        getIt<AttachmentFileStore>(),
      ),
    );
  }

  if (!getIt.isRegistered<AttachmentMetadataSync>()) {
    getIt.registerLazySingleton<AttachmentMetadataSync>(
      () => AttachmentMetadataSync(getIt<Dio>(), getIt<AttachmentStore>()),
    );
  }
  if (!getIt.isRegistered<AttachmentCapture>()) {
    getIt.registerLazySingleton<AttachmentCapture>(
      () => AttachmentCapture(
        getIt<AttachmentFileStore>(),
        getIt<AttachmentStore>(),
        getIt<Uuid>(),
      ),
    );
  }
  // Registered only when a feature declared an upload target. Without one there
  // is nothing to send, and the engine's file phase stays a single
  // `isRegistered` check.
  if (!getIt.isRegistered<AttachmentUploadProgress>()) {
    getIt.registerLazySingleton<AttachmentUploadProgress>(
      AttachmentUploadProgress.new,
    );
  }
  // **و`allOf` لا `getAll`** — والحارسُ `isRegistered` أمامه **يُعمي عن
  // التسجيلات المسمّاة**، و`injectable` يفرض الاسمَ لتسجيلين تحت نوعٍ واحد:
  // فمشروعٌ بهدفَي رفعٍ لشريحتين كان يُسكت الرفعَ كلَّه بلا سطرٍ أحمر واحد.
  // راجع `GetItGetAllOrEmpty`.
  if (!getIt.isRegistered<AttachmentUploadManager>()) {
    final targets = getIt.allOf<AttachmentUploadTarget>();
    if (targets.isNotEmpty) {
      getIt.registerLazySingleton<AttachmentUploadManager>(
        () => AttachmentUploadManager(
          getIt<AttachmentStore>(),
          targets,
          getIt<AttachmentUploadProgress>(),
        ),
      );
    }
  }

  if (!getIt.isRegistered<SyncCursorStore>()) {
    getIt.registerLazySingleton<SyncCursorStore>(
      () => SyncCursorStore(getIt<SyncDatabase>()),
    );
  }
  if (!getIt.isRegistered<SyncGate>()) {
    getIt.registerLazySingleton<SyncGate>(
      () => SyncGate(
        getIt<SyncSettingsStore>(),
        getIt<Connectivity>(),
        getIt<AuthNetworkGateway>(),
        // Already registered by `injection_module.dart` for
        // `InternetCheckerInterceptor` — the gate asks the same question, so it
        // asks the same probe rather than a second one that could disagree.
        getIt<InternetConnectionChecker>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncCycleStamp>()) {
    getIt.registerLazySingleton<SyncCycleStamp>(
      () => SyncCycleStamp(getIt<SyncDatabase>()),
    );
  }
  // ── تنزيلُ الصور والملفّات (الطورُ السادس) ──────────────────────────────────
  if (!getIt.isRegistered<MediaPrefetchStatus>()) {
    getIt.registerLazySingleton<MediaPrefetchStatus>(MediaPrefetchStatus.new);
  }
  if (!getIt.isRegistered<MediaPrefetchManager>()) {
    getIt.registerLazySingleton<MediaPrefetchManager>(
      // **و`ServerFileCache` هو المخزن نفسُه الذي تقرأ منه الشاشات** — فما
      // ينزّله هذا الطور تفتحه المصغَّرةُ بلا شبكة، ولا مخزنَ ثانٍ يفترق عنه.
      () => MediaPrefetchManager(
        getIt,
        getIt<ServerFileCache>(),
        getIt<Connectivity>(),
        getIt<SyncSettingsStore>(),
        getIt<MediaPrefetchStatus>(),
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
        getIt<SyncCycleStamp>(),
        getIt<SyncCursorStore>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncController>()) {
    getIt.registerLazySingleton<SyncController>(
      () => SyncController(
        getIt<SyncSettingsStore>(),
        getIt<Connectivity>(),
        getIt<SyncEngine>(),
        getIt<SyncGate>(),
        getIt<SyncQueueSignal>(),
        // مشروطةٌ بعلَمها — راجع `SyncController._lifecycle`.
        getIt.isRegistered<AppLifecycleService>()
            ? getIt<AppLifecycleService>()
            : null,
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
