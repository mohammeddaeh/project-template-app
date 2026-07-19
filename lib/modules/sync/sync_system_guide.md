# Sync System Guide

## A) System Overview

The sync system is an infrastructure SDK that provides durable local persistence, queued sync execution, and background/triggered synchronization controls for feature data.

It exists to:
- preserve data durability locally using SQLite
- support offline-first reads and deferred sync writes
- standardize write interception through a sync gateway
- centralize sync retries, backoff, and executor dispatch

### High-Level Architecture (Current Implementation)

`App bootstrap -> SyncSDK.initialize(config, di) -> registerSyncCore(di) -> apply settings -> apply repository decorators -> start SyncController`

`Feature Repository (sync-aware) -> SyncWriteGateway -> SQLite (synced_entities + sync_queue)`

`SyncController -> SyncEngine -> SyncExecutor(entityName) -> Remote API -> result -> queue/entity state update`

## B) Core Components Explanation

### SyncEngine
- File: `core/sync/engine/sync_engine.dart`
- Reads due jobs from queue and processes them in batches.
- Resolves executor by `entityName` using `getIt.getAll<SyncExecutor>()`.
- Handles success/failure:
  - success: mark entity as synced + delete queue job
  - failure: increment retry, schedule next retry, mark pending/failed by retry limit
- Guarded by `SyncLock` (storage-backed) to avoid concurrent engine runs; it
  survives app kills and auto-releases when stale (`releaseIfStale`).

### SyncManager
- **Not implemented as a concrete class.**
- Effective orchestration is currently split between:
  - `SyncSDK` (bootstrap lifecycle)
  - `SyncController` (trigger management)
  - `SyncEngine` (job processing)

### SyncRegistry
- **No standalone registry class exists.**
- Registry behavior is achieved via DI multi-binding:
  - `SyncRepositoryDecorator` instances via `getAll<SyncRepositoryDecorator>()`
  - `SyncExecutor` instances via `getAll<SyncExecutor>()`

### SyncHandlers
- **No dedicated `SyncHandler` abstraction currently exists in core/sync.**
- Equivalent role is performed by feature-level `SyncExecutor` implementations.

### SyncStrategies
- Implemented strategy-like pieces:
  - `SyncBackoffPolicy` (exponential retry delay)
  - `SyncConflictResolver` (clientWins/serverWins by version/updatedAt)
- No pluggable strategy registry exists yet.

### SyncResult / SyncTask Models
- `SyncQueueJob` is the persisted task model.
- `SyncExecutionResult` is the executor success model.
- Failures use `Either<ErrorModel, SyncExecutionResult>`.
- No separate `SyncResult` or `SyncTask` classes by those names.

## C) Data Flow

### 1) App Startup Sync

`App -> SyncSDK.initialize -> registerSyncCore -> SyncSettingsStore config apply -> applySyncRepositoryDecorators -> SyncController.init`

Then `SyncController` subscribes to connectivity changes and optional periodic timer.

### 2) Feature Sync Request Flow

Write path (when repository uses sync write interception):

`UseCase -> SyncableRepository.syncWrite -> SyncWriteGateway.write -> SQL transaction`

Transaction writes:
- upsert in `synced_entities`
- insert/update in `sync_queue` (only if active mode + enabled + enqueue=true)

### 3) Incremental Sync Flow

`SyncController trigger -> SyncEngine.runPendingJobs(batchSize)`

`SyncEngine -> getDueJobs(now) -> for each job -> resolve SyncExecutor(entityName) -> execute`

On failure:
- retry count++
- next retry time by `SyncBackoffPolicy`
- entity status pending/failed

On success:
- entity status synced
- queue job removed

### 4) Offline Fallback Flow

Current behavior depends on feature repository decorator implementation.

Example pattern used:
`Repository remote call fails -> read cached records from SyncEntityStore -> map to domain -> return to UI`

Core/sync provides storage and primitives; fallback behavior is implemented in feature sync-aware repository logic.

### 5) Conflict Resolution Flow

Provided utility:
`SyncConflictResolver.resolve(local, remote, strategy)`

Current rules:
- `clientWins` => keep local
- `serverWins` => prefer higher `version`, then newer `updatedAt`

Note: the resolver is invoked centrally by `SyncEngine._handleConflict` on every
HTTP 409, using the exact conflicting record (fetched by `entityId`).

### 6) Background Sync Flow

`SyncController`
- auto on connectivity event
- manual via `triggerManualSync()`
- periodic timer when configured

Before triggering engine, controller checks:
- mode must be `active`
- syncEnabled must be true
- internet available
- wifi-only condition (if enabled)

## D) Feature Onboarding Rules

Current practical onboarding (code truth):
1. Implement or generate a sync-aware repository decorator (`SyncRepositoryDecorator`) for the feature repository.
2. Ensure repository writes go through `SyncableRepository` -> `SyncWriteGateway`.
3. Provide a `SyncExecutor` for the feature `entityName`.
4. Ensure DI registers the decorator and executor (`injectable`).
5. Run generation (`build_runner`) and initialize SDK once.
6. Do not add sync logic in UI/Cubit.

Target declarative onboarding (documented in automation notes):
1. Add `SyncFeatureContract`
2. Generate sync adapter/executor files
3. Use generated DI bindings
4. No manual UI/Cubit wiring

## E) Automation System

### What SyncFeatureContract Is
- File: `core/sync/automation/sync_feature_contract.dart`
- Declarative contract for feature sync generation metadata:
  - `entityName`
  - repository contract type
  - `toJson`/`fromJson`
  - local id extraction

### How Code Generation Works (Current State)
- A design contract exists in `sync_codegen_notes.md`.
- Intended generator stack:
  - `build_runner` + `source_gen`
  - scan classes implementing `SyncFeatureContract<TEntity>`
  - emit feature sync files

### What Is Intended to Be Generated
- `<feature>_sync_repository_decorator.dart`
- `<feature>_sync_executor.dart`
- DI bindings via `injectable` annotations

### build_runner Integration
- Existing project already runs `build_runner` for `injectable`, `retrofit`, `freezed`, etc.
- For sync automation specifically, the guide notes intended integration, but no dedicated sync source_gen builder implementation is present in this codebase yet.

### Runtime Injection of Generated Files
- Runtime consumes DI-discovered instances:
  - decorators from `getAll<SyncRepositoryDecorator>()`
  - executors from `getAll<SyncExecutor>()`
- So generated files must include injectable annotations to become discoverable.

### Generated File Location (Intended)
- `Features/<feature>/data/sync/generated/`

## F) How Cursor / Developers Should Work With Sync System

### Rules
- NEVER call sync queue tables directly from UI or Cubit.
- ALWAYS keep sync orchestration in repository/infrastructure layers.
- NEVER bypass `SyncWriteGateway` for sync-intercepted writes.
- DO NOT place sync logic in presentation layer.
- Prefer declarative onboarding contracts once automation generator is implemented.

### Developer Checklist
- [ ] Create/extend feature repository in clean architecture layers.
- [ ] Ensure write interception path uses `SyncableRepository` + `syncWrite`.
- [ ] Define sync contract metadata (`SyncFeatureContract`) when automation is used.
- [ ] Run generator/build (`build_runner`).
- [ ] Verify decorator/executor are DI-discoverable.
- [ ] Initialize once via `SyncSDK.initialize(...)`.

## G) Edge Cases / Rules

### Offline Mode
- Engine does not run when no internet or mode not active.
- Writes remain durable in SQLite.

### Retry Strategy
- Exponential backoff (`2^retryCount * baseDelay`, capped by max delay).
- Retry metadata persisted in queue.

### Conflict Resolution
- Utility supports `serverWins` and `clientWins`.
- Currently opt-in usage by integration logic.

### Partial Sync vs Full Sync
- Engine processes jobs individually within a batch.
- Partial success is naturally supported: successful jobs are removed, failed jobs retried.

### Cache-First Rules
- Core provides entity store access.
- Actual cache-first/offline fallback behavior is defined in feature repository decorators.

## H) System Extensibility

### Add New Sync Strategy
- Add new policy/service in `core/sync/engine` or `core/sync/domain`.
- Inject into engine/controller where needed.

### Add New Handler Type
- Implement new `SyncExecutor` for an entity or operation family.
- Register via injectable annotation.

### Extend Automation Generator
- Implement source_gen builder for `SyncFeatureContract`.
- Emit generated decorator/executor + DI-annotated outputs.
- Keep generated outputs in feature `data/sync/generated`.

### Add New Feature Without Modifying Core
- Implement feature repository and sync executor/decorator (or generate them once generator exists).
- DI discovery and SDK lifecycle remain unchanged.

## Current Implementation Notes (Important)

- Core sync currently includes:
  - `SyncEngine`, `SyncController`, SQL stores/repositories, gateway, SDK bootstrap, conflict/backoff utilities.
- Core sync does **not** currently contain classes literally named:
  - `SyncManager`, `SyncRegistry`, `SyncHandler`, `SyncStrategy`, `SyncTask`, `SyncResult`.
- Equivalent behavior exists through SDK/controller/engine + DI discovery + queue/job/result models.
- Automation layer is currently a contract/design + documentation; full custom sync code generator implementation is not yet present in `core/sync/automation`.
