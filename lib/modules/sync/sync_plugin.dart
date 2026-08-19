/// The sync module's **only** entry point.
///
/// ```dart
/// import 'package:app_template/modules/sync/sync_plugin.dart';
/// ```
///
/// ## Why one file rather than a folder anyone may reach into
///
/// Everything under `lib/modules/sync/` other than this file is an
/// implementation detail — `SyncEngine`, the four `Sql*` stores, `SyncDatabase`,
/// `SyncLock`, `SyncGate`, `SyncBackoffPolicy`, `AttachmentFileStore`,
/// `SyncContractValidator`. None of them appears below, and a consumer that
/// needs one is describing a gap in this list, not a reason to import past it.
///
/// The rule is enforced rather than requested:
/// `test/sync/deletion_contract_test.dart` fails on any `import` of
/// `modules/sync/` from outside the module that does not end at this file. That
/// matters most for the thing it prevents silently — the module is planned to
/// roughly double in size (P4.5 / P3.5 in `PLAN.md`), and a deep import written
/// today becomes a migration the day an internal file is renamed.
///
/// The module's **own tests** are exempt: they exist to exercise the internals,
/// and routing them through a public surface would only prove that the surface
/// compiles.
///
/// ## What consumers do exist
///
/// | Consumer | Uses |
/// |---|---|
/// | `modules/modules_bootstrap.dart` | `SyncSDK` · `SyncSdkConfig` |
/// | `presentation/shared/sync/` | `SyncController` · `SyncQueueRepository` |
/// | `<feature>/data/sync/` | everything under "feature adapter" below |
///
/// The reference adapter is [`lib/Features/notes/data/sync/`] — six files that
/// import this one and nothing else from the module.
library;

// ── Lifecycle ────────────────────────────────────────────────────────────────
// Started once from `ModulesBootstrap`; a no-op when the flag is off.
export 'sdk/sync_sdk.dart' show SyncSDK;
export 'sdk/sync_sdk_config.dart' show SyncSdkConfig;
export 'config/sync_mode.dart' show SyncMode;

// ── Feature adapter: the contract ────────────────────────────────────────────
// One per synced entity. `SyncFeatureContract<T>` adds typed json mapping over
// `SyncFeatureContractBase`, which is what the engine actually resolves.
export 'automation/sync_feature_contract.dart'
    show SyncFeatureContract, SyncFeatureContractBase;

// `SyncConflictStrategy` is the per-entity policy hook declared on the contract;
// `SyncStatus` and `SyncJobType` describe a local row and a queued write.
export 'domain/sync_status.dart'
    show SyncStatus, SyncJobType, SyncConflictStrategy;

// ── Feature adapter: push ────────────────────────────────────────────────────
export 'engine/sync_job_executor.dart' show SyncExecutor, SyncExecutionResult;
export 'domain/sync_queue_job.dart' show SyncQueueJob;

// Metadata only — nothing reads it at runtime, and the engine keys executors off
// `SyncExecutor.entityName`. Exported because the reference adapter carries it.
export 'engine/sync_executor_for.dart' show SyncExecutorFor;

// ── Feature adapter: pull ────────────────────────────────────────────────────
// Optional: an entity with no pull executor is simply never pulled.
export 'engine/sync_pull_executor.dart'
    show SyncPullExecutor, SyncCursor, SyncPullPage;

// ── Feature adapter: the repository seam ─────────────────────────────────────
// `SyncRepositoryDecorator` swaps the bound repository at startup;
// `SyncableRepository` is what the swapped-in one must extend, and
// `SyncWriteGateway` is how it writes locally and queues the push in one step.
export 'integration/sync_repository_decorator.dart' show SyncRepositoryDecorator;
export 'domain/syncable_repository.dart' show SyncableRepository;
export 'domain/sync_write_gateway.dart' show SyncWriteGateway, SyncWriteCommand;

// ── Feature adapter: local reads ─────────────────────────────────────────────
// `readTyped` parses through the contract and pages by keyset cursor; `watch`
// emits whenever any of the three writers of `synced_entities` commits.
export 'domain/sync_entity_store.dart'
    show SyncEntityStore, SyncPageCursor, SyncTypedPage;
export 'domain/sync_entity_record.dart' show SyncEntityRecord;

// ── Observation ──────────────────────────────────────────────────────────────
// What `presentation/shared/sync/` needs: the pending count, and a manual
// trigger. The engine itself stays internal — nothing outside starts a cycle
// except through `SyncController`.
export 'domain/sync_queue_repository.dart' show SyncQueueRepository;
export 'integration/sync_controller.dart' show SyncController;

// ── Attachments ──────────────────────────────────────────────────────────────
// A feature gives itself attachments by implementing `AttachmentUploadTarget`;
// `attachmentFormData` builds the multipart body the server side expects.
export 'engine/attachment_upload_manager.dart'
    show AttachmentUploadTarget, attachmentFormData;

export 'domain/attachment_record.dart'
    show
        AttachmentRecord,
        AttachmentOrigin,
        AttachmentDownloadStatus,
        AttachmentUploadStatus;

// Listing what a row owns (`findForEntity`) and refreshing that list from the
// server. `SqlAttachmentStore` behind it stays internal, as does every other
// method on the interface that only the engine calls.
export 'domain/attachment_store.dart' show AttachmentStore;
export 'engine/attachment_metadata_sync.dart' show AttachmentMetadataSync;

// Reading a file back: `access()` serves it from private storage, fetches it
// resumably when online, and answers `AttachmentUnavailable(offline)` rather
// than reaching for a network that is not there.
export 'engine/attachment_download_manager.dart'
    show
        AttachmentDownloadManager,
        AttachmentAccess,
        AttachmentReady,
        AttachmentUnavailable,
        AttachmentUnavailability;

// Ingesting a file the device just produced, before anything is queued.
export 'engine/attachment_capture.dart' show AttachmentCapture;
